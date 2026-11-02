import os
import boto3
import json
import logging
from datetime import datetime, timedelta
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from decimal import Decimal
from botocore.exceptions import ClientError

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize AWS clients
sts = boto3.client('sts')

# Environment variables
ACCOUNTS_JSON = os.environ.get('ACCOUNTS', '{}')
AUTO_DISCOVER_ACCOUNTS = os.environ.get('AUTO_DISCOVER_ACCOUNTS', 'false').lower() == 'true'
EXCLUDED_ACCOUNT_IDS = os.environ.get('EXCLUDED_ACCOUNT_IDS', '').split(',') if os.environ.get('EXCLUDED_ACCOUNT_IDS') else []

ACCOUNTS = json.loads(ACCOUNTS_JSON) if ACCOUNTS_JSON != '{}' else {}

# Validate required email configuration
SENDER = os.environ.get('SENDER')
RECIPIENT = os.environ.get('RECIPIENT', '')

# Parse recipients, filtering out empty strings and whitespace
RECIPIENTS = [email.strip() for email in RECIPIENT.split(',') if email.strip()]

if not SENDER:
    raise ValueError("SENDER environment variable is required but not set")
if not RECIPIENTS:
    raise ValueError("RECIPIENT environment variable is required but not set or empty")

if FORCE_DATE := os.environ.get("FORCE_DATE"):
    FORCE_DATE = datetime.strptime(FORCE_DATE, "%Y-%m-%d")  # e.g. 2023-08-30
# Environment variables are strings: "false" is truthy, so compare explicitly
EXCLUDE_CREDITS = os.environ.get('EXCLUDE_CREDITS', 'true').strip().lower() == 'true'
REGION = os.environ.get('REGION', 'us-east-1')


# Function to discover accounts from AWS Organizations
def discover_accounts():
    """
    Discover all active AWS accounts in the organization.
    Assumes LambdaCostsExplorerAccess role in management account to access Organizations API.
    Returns a dictionary of account names to account info.
    """
    try:
        # Get management account ID from ACCOUNTS variable
        management_account = ACCOUNTS.get('management')
        if not management_account or not management_account.get('id'):
            logger.error("Cannot discover accounts: management account not found in ACCOUNTS variable")
            return {}

        management_account_id = management_account['id']

        # Assume LambdaCostsExplorerAccess role in management account
        # This role needs organizations:ListAccounts permission in the management account
        role_arn = f"arn:aws:iam::{management_account_id}:role/LambdaCostsExplorerAccess"
        logger.info(f"Assuming role {role_arn} to access AWS Organizations")

        assumed_role = sts.assume_role(
            RoleArn=role_arn,
            RoleSessionName='LambdaOrganizationsDiscovery'
        )

        # Create Organizations client with assumed credentials
        temp_session = boto3.Session(
            aws_access_key_id=assumed_role['Credentials']['AccessKeyId'],
            aws_secret_access_key=assumed_role['Credentials']['SecretAccessKey'],
            aws_session_token=assumed_role['Credentials']['SessionToken']
        )
        organizations = temp_session.client('organizations')

        accounts = {}
        paginator = organizations.get_paginator('list_accounts')

        for page in paginator.paginate():
            for account in page['Accounts']:
                # Skip suspended accounts and excluded accounts
                if account['Status'] != 'ACTIVE':
                    logger.info(f"Skipping account {account['Name']} ({account['Id']}) - Status: {account['Status']}")
                    continue

                if account['Id'] in EXCLUDED_ACCOUNT_IDS:
                    logger.info(f"Skipping account {account['Name']} ({account['Id']}) - Excluded")
                    continue

                accounts[account['Name']] = {
                    'id': account['Id'],
                    'email': account.get('Email', ''),
                    'status': account['Status']
                }

        logger.info(f"Discovered {len(accounts)} active accounts from AWS Organizations")
        return accounts

    except ClientError as e:
        error_code = e.response['Error']['Code']
        if error_code == 'AccessDeniedException':
            logger.error(f"Access denied to AWS Organizations API. Ensure the management account ({management_account_id}) has LambdaCostsExplorerAccess role with organizations:ListAccounts permission.")
        else:
            logger.error(f"Error discovering accounts from Organizations: {str(e)}")
        return {}
    except Exception as e:
        logger.error(f"Unexpected error discovering accounts: {str(e)}")
        return {}

# Function to assume role in another account and create an AWS Cost Explorer client
def create_ce_client(account_id):
    """
    Create a Cost Explorer client by assuming a role in the target account.
    Returns None if role assumption fails.
    """
    role_arn = f"arn:aws:iam::{account_id}:role/LambdaCostsExplorerAccess"
    try:
        assumed_role = sts.assume_role(
            RoleArn=role_arn,
            RoleSessionName='AssumedRoleSession'
        )

        temp_session = boto3.Session(
            aws_access_key_id=assumed_role['Credentials']['AccessKeyId'],
            aws_secret_access_key=assumed_role['Credentials']['SecretAccessKey'],
            aws_session_token=assumed_role['Credentials']['SessionToken']
        )

        # Cost Explorer API endpoint (ce.us-east-1.amazonaws.com) is only available in us-east-1
        # This provides cost data for all AWS regions from a single endpoint
        # See: https://docs.aws.amazon.com/general/latest/gr/billing.html
        return temp_session.client('ce', region_name='us-east-1')
    except ClientError as e:
        logger.error(f"Failed to assume role {role_arn}: {str(e)}")
        return None
    except Exception as e:
        logger.error(f"Unexpected error assuming role {role_arn}: {str(e)}")
        return None

# Function to fetch AWS Cost Explorer data
def get_cost_data(ce_client, account_id, start_date_str, end_date_str, tag_key=None, tag_value=None):
    dimensions_filter = {
        'Dimensions': {
            'Key': 'LINKED_ACCOUNT',
            'Values': [str(account_id)]
        }
    }

    if tag_key and tag_value:
        tags_filter = {
            'Tags': {
                'Key': tag_key,
                'Values': [tag_value],
                'MatchOptions': ['EQUALS']
            }
        }
        combined_filter = {
            'And': [dimensions_filter, tags_filter]
        }
    else:
        combined_filter = dimensions_filter

    if EXCLUDE_CREDITS:
        filters_credits = {
            "Not": {
                'Dimensions': {
                    'Key': 'RECORD_TYPE',
                    'Values': ['Credit', 'Refund']
                }
            }
        }
        combined_filter = {
            'And': [combined_filter, filters_credits]
        }

    # Get cost and usage data
    response = ce_client.get_cost_and_usage(
        TimePeriod={
            'Start': start_date_str,
            'End': end_date_str
        },
        Granularity='MONTHLY',
        Metrics=['UnblendedCost'],
        Filter=combined_filter,
        GroupBy=[
            {
                'Type': 'DIMENSION',
                'Key': 'SERVICE'
            }
        ]
    )

    return response['ResultsByTime'][0]['Groups']


def costs_by_service(groups):
    """{service: cost} from Cost Explorer groups keyed by SERVICE."""
    return {group['Keys'][0]: Decimal(group['Metrics']['UnblendedCost']['Amount']) for group in groups}


def parse_tags(tags_json):
    """The cost allocation tags to report on, as {key: value}; raises on invalid input."""
    try:
        tags = json.loads(tags_json)
    except json.JSONDecodeError as e:
        raise ValueError(f"TAGS_JSON is not valid JSON: {e}") from e
    if not isinstance(tags, dict):
        raise ValueError("TAGS_JSON is not a valid dictionary")
    if len(tags) > 3:
        raise ValueError(f"Only up to 3 tags are allowed, got {len(tags)}")
    return tags


# Function to calculate cost variation percentage
def calculate_variation(prev_cost, current_cost):
    # Check if the previous month's cost was < $0.01
    if prev_cost < 0.01:
        # If the current month's cost is > $0.01, set the percentage to 100%
        if current_cost > 0.01:
            return 100.0
        # If the current month's cost is also < $0.01, set the percentage to 0%
        else:
            return 0.0
    # Calculate percentage change as usual for other cases
    else:
        return ((current_cost - prev_cost) / prev_cost) * 100

# Function to generate an HTML table
def generate_html_table(account_name, cost_data, ce_client, start_date_str, end_date_str, prev_start_date_str, prev_end_date_str, tags):
    # Calculate the cost data for the previous month
    account_id = ACCOUNTS[account_name]['id']
    current_cost_dict = costs_by_service(cost_data)
    prev_cost_data_dict = costs_by_service(get_cost_data(ce_client, account_id, prev_start_date_str, prev_end_date_str))

    # One query per tag, grouped by service like the main query, so each row
    # shows that service's tagged cost (not the whole account's on every row)
    tag_costs_by_service = {
        tag_key: costs_by_service(get_cost_data(ce_client, account_id, start_date_str, end_date_str, tag_key, tag_value))
        for tag_key, tag_value in tags.items()
    }

    # List services from both months, so one that dropped to $0 still shows
    services = sorted(
        set(current_cost_dict) | set(prev_cost_data_dict),
        key=lambda s: (current_cost_dict.get(s, Decimal(0)), prev_cost_data_dict.get(s, Decimal(0)), s),
        reverse=True,
    )

    # Calculate the month name from start_date_str
    last_month_name = datetime.strptime(start_date_str, '%Y-%m-%d').strftime('%B')

    html_table = f'<h1>AWS Cost Report - {account_name} (Account ID: {ACCOUNTS[account_name]["id"]})</h1>'
    tag_headers = ' '.join(f'<th style="width: 12%; padding: 10px; text-align: right;">Tag {tag_key}</th>' for tag_key in tags)

    html_table += f"""<table border='1' style='width: 100%; border-collapse: collapse;'>
                        <thead>
                            <tr style='background-color: #f2f2f2;'>
                                <th style='width: 40%; padding: 10px; text-align: left;'>Service</th>
                                <th style='width: 12.5%; padding: 10px; text-align: right;'>Cost on {last_month_name}</th>
                                <th style='width: 12.5%; padding: 10px; text-align: right;'>Cost on Previous Month</th>
                                <th style='width: 12.5%; padding: 10px; text-align: right;'>Variation %</th>
                                {tag_headers}
                            </tr>
                        </thead><tbody>"""

    total_cost = Decimal(0)
    total_prev_month_cost = Decimal(0)
    total_tag_costs = {tag_key: Decimal(0) for tag_key in tags}

    for service in services:
        current_cost = current_cost_dict.get(service, Decimal(0)).quantize(Decimal('0.00'))  # Round to 2 decimals
        prev_month_cost = prev_cost_data_dict.get(service, Decimal(0)).quantize(Decimal('0.00'))  # Round to 2 decimals

        variation_percent = calculate_variation(prev_month_cost, current_cost)
        variation_color = 'red' if variation_percent > 0 else 'green'

        # Initialize the row with service name, current cost, previous month cost, and variation
        row = [f'<td>{service}</td>',
               f'<td style="text-align:right;">${current_cost:.2f}</td>',
               f'<td style="text-align:right;">${prev_month_cost:.2f}</td>',
               f'<td style="text-align:right; color:{variation_color};">{variation_percent:.2f}%</td>']

        # Add this service's cost for each tag ($0.00 when none of it carries the tag)
        for tag_key in tags:
            tag_cost_amount = tag_costs_by_service[tag_key].get(service, Decimal(0)).quantize(Decimal('0.00'))
            row.append(f'<td style="text-align:right;">${tag_cost_amount:.2f}</td>')
            total_tag_costs[tag_key] += tag_cost_amount

        html_table += '<tr>' + ' '.join(row) + '</tr>'

        total_cost += current_cost
        total_prev_month_cost += prev_month_cost


    variation_percent_month_to_month = calculate_variation(total_prev_month_cost, total_cost)
    variation_color_month_to_month = 'red' if variation_percent_month_to_month > 0 else 'green'
    variation_total = f'<td style="text-align:right; color:{variation_color_month_to_month};">{variation_percent_month_to_month:.2f}%</td>'

    # Add total columns for each tag, ensuring alignment
    total_row = [f'<td><b>Total</b></td>',
                 f'<td style="text-align:right;"><b>${total_cost:.2f}</b></td>',
                 f'<td style="text-align:right;"><b>${total_prev_month_cost:.2f}</b></td>',
                 variation_total]

    # Add total tag costs to the total row
    for tag_key in tags:
        total_row.append(f'<td style="text-align:right;"><b>${total_tag_costs[tag_key]:.2f}</b></td>')

    html_table += '<tr>' + ' '.join(total_row) + '</tr>'

    html_table += '</table>'
    return html_table


# Function to send an email using Amazon SES: one message to every recipient
def send_email(subject, body, recipients):
    ses = boto3.client('ses', region_name=REGION)

    ses.send_email(
        Source=SENDER,
        Destination={'ToAddresses': recipients},
        Message={
            'Subject': {'Data': subject},
            'Body': {'Html': {'Data': body}}
        }
    )

def lambda_handler(event, context):
    aggregated_html_tables = []
    failed_accounts = []

    logger.info("Starting MonthlyServicesUsage Lambda execution")

    # Validate the input before spending any Cost Explorer requests. Raise, not
    # return: only an exception counts as an Errors metric, so a returned
    # status code would leave the alarm silent and send no email.
    tags = parse_tags(os.environ.get('TAGS_JSON', '{}'))

    # Determine accounts to process
    if AUTO_DISCOVER_ACCOUNTS:
        logger.info("Auto-discovery enabled - fetching accounts from AWS Organizations")
        discovered_accounts = discover_accounts()
        if discovered_accounts:
            global ACCOUNTS
            ACCOUNTS = discovered_accounts
            logger.info(f"Using {len(ACCOUNTS)} discovered accounts")
        else:
            logger.warning("Auto-discovery failed or returned no accounts. Falling back to configured ACCOUNTS.")
            if not ACCOUNTS:
                raise RuntimeError("No accounts available to process")
    else:
        logger.info(f"Using {len(ACCOUNTS)} configured accounts")

    ########################
    # IMPORTANT:
    # The start date is inclusive, but the end date is exclusive.
    # For example, if start is 2023-01-01 and end is 2023-05-01,
    # then the cost and usage data is retrieved from 2023-01-01 up to and including 2023-04-30 but not including 2023-05-01.
    ######################

    # Calculate the start and end dates for the past month (e.g., August)
    current_date = FORCE_DATE or datetime.now()
    end_date = current_date.replace(day=1) - timedelta(days=1)
    start_date = end_date.replace(day=1)
    start_date_str = start_date.strftime("%Y-%m-%d")
    end_date += timedelta(days=1)  # Increment the end date by one day
    end_date_str = end_date.strftime("%Y-%m-%d")

    # Calculate the start and end dates for the month before the past month (e.g., July)
    prev_end_date = start_date - timedelta(days=1)
    prev_start_date = prev_end_date.replace(day=1)
    prev_start_date_str = prev_start_date.strftime("%Y-%m-%d")
    prev_end_date += timedelta(days=1)  # Increment the end date by one day
    prev_end_date_str = prev_end_date.strftime("%Y-%m-%d")


    for account_name, account_info in ACCOUNTS.items():
        logger.info(f"Processing account: {account_name} (ID: {account_info['id']})")
        ce_client = create_ce_client(account_info['id'])

        if ce_client is None:
            logger.warning(f"Skipping account {account_name} - failed to create CE client")
            failed_accounts.append(account_name)
            continue

        try:
            cost_data = get_cost_data(ce_client, account_info['id'], start_date_str, end_date_str)
            html_table = generate_html_table(account_name, cost_data, ce_client, start_date_str, end_date_str, prev_start_date_str, prev_end_date_str, tags)
            aggregated_html_tables.append(html_table)
            logger.info(f"Successfully processed account {account_name}")
        except Exception as e:
            logger.error(f"Error processing account {account_name}: {str(e)}")
            failed_accounts.append(account_name)
            continue

    # Log summary of failed accounts
    if failed_accounts:
        logger.warning(f"Failed to process {len(failed_accounts)} account(s): {', '.join(failed_accounts)}")

    # Check if we have at least one successful table
    if not aggregated_html_tables:
        error_msg = f"Failed to process all {len(failed_accounts)} accounts: {', '.join(failed_accounts)}"
        logger.error(error_msg)
        raise RuntimeError(error_msg)

    # Add failure notice to email if some accounts failed
    failure_notice = ""
    if failed_accounts:
        failure_notice = f"<div style='background-color: #fff3cd; padding: 15px; margin-bottom: 20px; border: 1px solid #ffc107;'>" \
                       f"<strong>Warning:</strong> Failed to retrieve cost data for the following account(s): {', '.join(failed_accounts)}" \
                       f"</div>"

    # Send a single email containing all the tables
    subject = 'AWS Cost Summary Report'
    body = f'<html><body>{failure_notice}' + ''.join(aggregated_html_tables) + '</body></html>'

    send_email(subject, body, RECIPIENTS)

    logger.info("Email sent successfully")
    return {
        'statusCode': 200,
        'body': json.dumps({
            'message': 'Email sent successfully',
            'processed_accounts': len(aggregated_html_tables),
            'failed_accounts': len(failed_accounts),
            'failed_account_names': failed_accounts
        })
    }