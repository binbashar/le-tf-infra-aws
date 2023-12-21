import os
import boto3
import json
from datetime import datetime, timedelta
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from decimal import Decimal

# Initialize AWS STS client to assume roles in other accounts
sts = boto3.client('sts')

# Environment variables
ACCOUNTS_JSON = os.environ.get('ACCOUNTS', '{}')

ACCOUNTS = json.loads(ACCOUNTS_JSON)
SENDER = os.environ.get('SENDER')
RECIPIENTS = os.environ.get('RECIPIENT').split(',')
if FORCE_DATE := os.environ.get("FORCE_DATE"):
    FORCE_DATE = datetime.strptime(FORCE_DATE, "%Y-%m-%d")  # e.g. 2023-08-30
EXCLUDE_CREDITS = os.environ.get('EXCLUDE_CREDITS')
REGION = os.environ.get('REGION', 'us-east-1')


# Function to assume role in another account and create an AWS Cost Explorer client
def create_ce_client(account_id):
    role_arn = f"arn:aws:iam::{account_id}:role/LambdaCostsExplorerAccess"  # Replace with the appropriate role ARN
    assumed_role = sts.assume_role(
        RoleArn=role_arn,
        RoleSessionName='AssumedRoleSession'
    )

    temp_session = boto3.Session(
        aws_access_key_id=assumed_role['Credentials']['AccessKeyId'],
        aws_secret_access_key=assumed_role['Credentials']['SecretAccessKey'],
        aws_session_token=assumed_role['Credentials']['SessionToken']
    )

    return temp_session.client('ce')

# Function to fetch AWS Cost Explorer data
def get_cost_data(ce_client, account_id, start_date_str, end_date_str, tag_key=None, tag_value=None):
    dimensions_filter = {
        'Dimensions': {
            'Key': 'LINKED_ACCOUNT',
            'Values': [account_id]
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

    # Check if EXCLUDE_CREDITS is set to 'True' in the environment variables
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

# Function to fetch costs associated with a specific tag
def get_tag_cost(ce_client, account_id, tag_key, tag_value, start_date_str, end_date_str):
    return get_cost_data(ce_client, account_id, start_date_str, end_date_str, tag_key, tag_value)

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
    prev_cost_data = get_cost_data(ce_client, ACCOUNTS[account_name]['id'], prev_start_date_str, prev_end_date_str)
    prev_cost_data_dict = {group['Keys'][0]: Decimal(group['Metrics']['UnblendedCost']['Amount']) for group in prev_cost_data}

    # Calculate the total cost of the previous month
    total_prev_month_cost = sum(prev_cost_data_dict.values())

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

    for group in cost_data:
        service = group['Keys'][0]
        current_cost = Decimal(group['Metrics']['UnblendedCost']['Amount']).quantize(Decimal('0.00'))  # Round to 2 decimals
        prev_month_cost = prev_cost_data_dict.get(service, Decimal(0)).quantize(Decimal('0.00'))  # Round to 2 decimals

        variation_percent = calculate_variation(prev_month_cost, current_cost)
        variation_color = 'red' if variation_percent > 0 else 'green'

        # Initialize the row with service name, current cost, previous month cost, and variation
        row = [f'<td>{service}</td>',
               f'<td style="text-align:right;">${current_cost:.2f}</td>',
               f'<td style="text-align:right;">${prev_month_cost:.2f}</td>',
               f'<td style="text-align:right; color:{variation_color};">{variation_percent:.2f}%</td>']
        
        # Add cost columns for each tag, or an empty cell if the tag doesn't exist for this service
        for tag_key, tag_value in tags.items():
            tag_cost = get_tag_cost(ce_client, ACCOUNTS[account_name]['id'], tag_key, tag_value, start_date_str, end_date_str)
            tag_cost_amount = sum(Decimal(group['Metrics']['UnblendedCost']['Amount']) for group in tag_cost)
            row.append(f'<td style="text-align:right;">${tag_cost_amount:.2f}</td>')
            total_tag_costs[tag_key] += tag_cost_amount

        # Ensure that each row has the same number of columns
        while len(row) < len(tags) + 4:
            row.append('<td></td>')

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
    for tag_key, tag_value in tags.items():
        total_row.append(f'<td style="text-align:right;"><b>${total_tag_costs[tag_key]:.2f}</b></td>')

    html_table += '<tr>' + ' '.join(total_row) + '</tr>'

    html_table += '</table>'
    return html_table


    # Function to send an email using Amazon SES
def send_email(subject, body, recipient):
    ses = boto3.client('ses', region_name=REGION)

    ses.send_email(
        Source=SENDER,
        Destination={'ToAddresses': [recipient]},
        Message={
            'Subject': {'Data': subject},
            'Body': {'Html': {'Data': body}}
        }
    )

def lambda_handler(event, context):
    aggregated_html_tables = []
    
    # Parse the JSON string for tags
    tags_json = os.environ.get('TAGS_JSON', '{}')
    tags = json.loads(tags_json)
    
    # Don't allow more than 3 tags
    if len(tags) > 3:
        return {
            'statusCode': 400,
            'body': 'Only up to 3 tags are allowed.'
        }
    
    
    if not isinstance(tags, dict):
        # Handle the case where TAGS_JSON is not a valid dictionary
        return {
            'statusCode': 400,
            'body': 'TAGS_JSON is not a valid dictionary.'
        }

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

    
    # Fetch the cost associated the given tags for the entire previous month
    # for each AWS account before entering the loop
    tag_costs = {}
    for account_name, account_info in ACCOUNTS.items():
        ce_client = create_ce_client(account_info['id'])
        # Loop through each tag and fetch cost data
        for tag_key, tag_value in tags.items():
            tag_cost_data = get_tag_cost(ce_client, account_info['id'], tag_key, tag_value, start_date_str, end_date_str)
            tag_cost = sum(Decimal(group['Metrics']['UnblendedCost']['Amount']) for group in tag_cost_data)
            tag_costs[account_name] = tag_cost

    # Enter the loop for each AWS account and service
    for account_name, account_info in ACCOUNTS.items():
        ce_client = create_ce_client(account_info['id'])
        
        # Check if the account_name exists in tag_costs
        if account_name in tag_costs:
            prev_cost = tag_costs[account_name]
        else:
            # Handle the case where tag_costs doesn't contain the key
            prev_cost = Decimal(0)
        
        cost_data = get_cost_data(ce_client, account_info['id'], start_date_str, end_date_str)
        cost_data.sort(key=lambda x: Decimal(x['Metrics']['UnblendedCost']['Amount']), reverse=True)

        # prev_cost = tag_costs[account_name]
        html_table = generate_html_table(account_name, cost_data, ce_client, start_date_str, end_date_str, prev_start_date_str, prev_end_date_str, tags)
        aggregated_html_tables.append(html_table)

    # Send a single email containing all the tables
    subject = 'AWS Cost Summary Report'
    body = '<html><body>' + ''.join(aggregated_html_tables) + '</body></html>'

    for recipient in RECIPIENTS:
        send_email(subject, body, recipient)

    return {
        'statusCode': 200,
        'body': 'Email sent successfully'
    }