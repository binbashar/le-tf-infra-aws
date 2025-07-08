#
# Source: https://github.com/iandees/aws-billing-to-slack/tree/master
#
from collections import defaultdict
import boto3
import datetime
import os
import requests
import sys

n_days = 7
today = datetime.datetime.today()
yesterday = today - datetime.timedelta(days=1)
week_ago = today - datetime.timedelta(days=n_days)

# It seems that the sparkline symbols don't line up (probably based on font?) so put them last
# Also, leaving out the full block because Slack doesn't like it: '█'
sparks = ['▁', '▂', '▃', '▄', '▅', '▆', '▇']

def sparkline(datapoints):
    lower = min(datapoints)
    upper = max(datapoints)
    n_sparks = len(sparks) - 1

    line = ""
    for dp in datapoints:
        scaled = 1 if upper == 0 else dp/upper
        which_spark = round(scaled * n_sparks)
        line += (sparks[which_spark])

    return line


def delta(costs):
    if (len(costs) > 1 and costs[-1] >= 1 and costs[-2] >= 1):
        # This only handles positive numbers
        result = ((costs[-1]/costs[-2])-1)*100.0
    else:
        result = 0
    return result


def find_by_key(values: list, key: str, value: str):
    for item in values:
        if item.get(key) == value:
            return item
    return None


def get_secret(secret_identifier):
    """
    Get secret value from AWS Secrets Manager.
    
    Args:
        secret_identifier: Can be either:
            - Secret name (e.g., 'my-secret')
            - Full ARN (e.g., 'arn:aws:secretsmanager:us-east-1:123456789012:secret:my-secret-ABC123')
            - Partial ARN (e.g., 'us-east-1:123456789012:secret:my-secret')
    
    Returns:
        str: The secret value
    """
    session = boto3.session.Session()
    client = session.client(service_name='secretsmanager')
    get_secret_value_response = client.get_secret_value(SecretId=secret_identifier)
    return get_secret_value_response['SecretString']


def lambda_handler(event, context):
    group_by = os.environ.get("GROUP_BY", "SERVICE")
    length = int(os.environ.get("LENGTH", "5"))
    cost_aggregation = os.environ.get("COST_AGGREGATION", "UnblendedCost")

    summary, buffer, data = report_cost(group_by=group_by, length=length, cost_aggregation=cost_aggregation)

    slack_hook_url = None
    slack_secret_id = os.environ.get('SLACK_WEBHOOK_SECRET_ID')
    if slack_secret_id:
        slack_hook_url = get_secret(slack_secret_id)
    else:
        slack_hook_url = os.environ.get('SLACK_WEBHOOK_URL')

    if slack_hook_url:
        publish_slack(slack_hook_url, summary, buffer)

    teams_hook_url = os.environ.get('TEAMS_WEBHOOK_URL')
    if teams_hook_url:
        publish_teams(teams_hook_url, summary, buffer)
    
    google_hook_url = os.environ.get('GOOGLE_WEBHOOK_URL')
    if google_hook_url:
        publish_google(google_hook_url, summary, buffer)

def report_cost(group_by: str = "SERVICE", length: int = 5, cost_aggregation: str = "UnblendedCost", result: dict = None, yesterday: str = None, new_method=True):

    if yesterday is None:
        yesterday = today - datetime.timedelta(days=1)
    else:
        yesterday = datetime.datetime.strptime(yesterday, '%Y-%m-%d')

    week_ago = today - datetime.timedelta(days=n_days)
    # Generate list of dates, so that even if our data is sparse,
    # we have the correct length lists of costs (len is n_days)
    list_of_dates = [
        (week_ago + datetime.timedelta(days=x)).strftime('%Y-%m-%d')
        for x in range(n_days)
    ]
    print(yesterday)
    print(list_of_dates)

    # Get account account name from env, or account id/account alias from boto3
    account_name = os.environ.get("AWS_ACCOUNT_NAME", None)
    if account_name is None:
        iam = boto3.client("iam")
        paginator = iam.get_paginator("list_account_aliases")
        for aliases in paginator.paginate(PaginationConfig={"MaxItems": 1}):
            if "AccountAliases" in aliases and len(aliases["AccountAliases"]) > 0:
                account_name = aliases["AccountAliases"][0]

    if account_name is None:
        account_name = boto3.client("sts").get_caller_identity().get("Account")

    if account_name is None:
        account_name = "[NOT FOUND]"

    client = boto3.client('ce')

    query = {
        "TimePeriod": {
            "Start": week_ago.strftime('%Y-%m-%d'),
            "End": today.strftime('%Y-%m-%d'),
        },
        "Granularity": "DAILY",
        "Filter": {
            "Not": {
                "Dimensions": {
                    "Key": "RECORD_TYPE",
                    "Values": [
                        "Credit",
                        "Refund",
                        "Upfront",
                        "Support",
                    ]
                }
            }
        },
        "Metrics": [cost_aggregation],
        "GroupBy": [
            {
                "Type": "DIMENSION",
                "Key": group_by,
            },
        ],
    }

    # Only run the query when on lambda, not when testing locally with example json
    if result is None:
        result = client.get_cost_and_usage(**query)

    cost_per_day_by_service = defaultdict(list)

    if new_method == False:
        # Build a map of service -> array of daily costs for the time frame
        for day in result['ResultsByTime']:
            for group in day['Groups']:
                key = group['Keys'][0]
                cost = float(group['Metrics'][cost_aggregation]['Amount'])
                cost_per_day_by_service[key].append(cost)
    else:
        # New method, which first creates a dict of dicts
        # then loop over the services and loop over the list_of_dates
        # and this means even for sparse data we get a full list of costs
        cost_per_day_dict = defaultdict(dict)

        for day in result['ResultsByTime']:
            start_date = day["TimePeriod"]["Start"]
            for group in day['Groups']:
                key = group['Keys'][0]
                if group_by == "LINKED_ACCOUNT":
                    dimension = find_by_key(result["DimensionValueAttributes"], "Value", key)
                    if dimension:
                        key += " ("+dimension["Attributes"]["description"]+")"
                cost = float(group['Metrics'][cost_aggregation]['Amount'])
                cost_per_day_dict[key][start_date] = cost

        for key in cost_per_day_dict.keys():
            for start_date in list_of_dates:
                cost = cost_per_day_dict[key].get(start_date, 0.0)  # fallback for sparse data
                cost_per_day_by_service[key].append(cost)

    # Sort the map by yesterday's cost
    most_expensive_yesterday = sorted(cost_per_day_by_service.items(), key=lambda i: i[1][-1], reverse=True)

    service_names = [k for k,_ in most_expensive_yesterday[:length]]
    longest_name_len = len(max(service_names, key = len))

    buffer = f"{'Service':{longest_name_len}} ${'Yday':8} {'∆%':>5} {'Last '}{n_days}{'d':7}\n"

    for service_name, costs in most_expensive_yesterday[:length]:
        buffer += f"{service_name:{longest_name_len}} ${costs[-1]:8,.2f} {delta(costs):4.0f}% {sparkline(costs):7}\n"

    other_costs = [0.0] * n_days
    for service_name, costs in most_expensive_yesterday[length:]:
        for i, cost in enumerate(costs):
            other_costs[i] += cost

    buffer += f"{'Other':{longest_name_len}} ${other_costs[-1]:8,.2f} {delta(other_costs):4.0f}% {sparkline(other_costs):7}\n"

    total_costs = [0.0] * n_days
    for day_number in range(n_days):
        for service_name, costs in most_expensive_yesterday:
            try:
                total_costs[day_number] += costs[day_number]
            except IndexError:
                total_costs[day_number] += 0.0

    buffer += f"{'Total':{longest_name_len}} ${total_costs[-1]:8,.2f} {delta(total_costs):4.0f}% {sparkline(total_costs):7}\n"

    cost_per_day_by_service["total"] = total_costs[-1]

    credits_expire_date = os.environ.get('CREDITS_EXPIRE_DATE')
    if credits_expire_date:
        credits_expire_date = datetime.datetime.strptime(credits_expire_date, "%m/%d/%Y")

        credits_remaining_as_of = os.environ.get('CREDITS_REMAINING_AS_OF')
        credits_remaining_as_of = datetime.datetime.strptime(credits_remaining_as_of, "%m/%d/%Y")

        credits_remaining = float(os.environ.get('CREDITS_REMAINING'))

        days_left_on_credits = (credits_expire_date - credits_remaining_as_of).days
        allowed_credits_per_day = credits_remaining / days_left_on_credits

        relative_to_budget = (total_costs[-1] / allowed_credits_per_day) * 100.0

        if relative_to_budget < 60:
            emoji = ":white_check_mark:"
        elif relative_to_budget > 110:
            emoji = ":rotating_light:"
        else:
            emoji = ":warning:"

        summary = (f"{emoji} Yesterday's cost for {account_name} ${total_costs[-1]:,.2f} "
                   f"is {relative_to_budget:.2f}% of credit budget "
                   f"${allowed_credits_per_day:,.2f} for the day."
                  )
    else:
        summary = f"Yesterday's cost for account {account_name} was ${total_costs[-1]:,.2f}"

    return summary, buffer, cost_per_day_by_service


def publish_slack(hook_url, summary, buffer):

    resp = requests.post(
        hook_url,
        json={
            "text": summary + "\n\n```\n" + buffer + "\n```",
        }
    )

    if resp.status_code != 200:
        print("HTTP %s: %s" % (resp.status_code, resp.text))


def publish_teams(hook_url, summary, buffer):

    resp = requests.post(
        hook_url,
        json={
            "text": summary + "\n\n```\n" + buffer + "\n```",
        }
    )

    if resp.status_code != 200:
        print("HTTP %s: %s" % (resp.status_code, resp.text))

def publish_google(hook_url, summary, buffer):

    message = {
        "text": summary + "\n\n```\n" + buffer + "\n```"
    }
    
    resp = requests.post(hook_url, json=message)

    if resp.status_code != 200:
        print("HTTP %s: %s" % (resp.status_code, resp.text))

if __name__ == "__main__":
    # for running locally to test
    # IMPORTANT: you may need to update the dates in the .json files since the
    #  report_cost will look for entries that fall within the past week.
    import json
    with open("example_boto3_result.json", "r") as f:
        example_result = json.load(f)
    with open("example_boto3_result2.json", "r") as f:
        example_result2 = json.load(f)

    # summary, buffer, data = report_cost(group_by="LINKED_ACCOUNT")
    # print(summary)
    # print(buffer)
    #
    # summary, buffer, data = report_cost(group_by="REGION")
    # print(summary)
    # print(buffer)
    #
    # summary, buffer, data = report_cost(group_by="USAGE_TYPE", length=20)
    # print(summary)
    # print(buffer)
    #
    # summary, buffer, data = report_cost(group_by="SERVICE", length=20)
    # print(summary)
    # print(buffer)
    # summary, buffer, data = report_cost(group_by="SERVICE", length=5, cost_aggregation="UnblendedCost")
    # print(summary)
    # print(buffer)
    # summary, buffer, data = report_cost(group_by="SERVICE", length=5, cost_aggregation="AmortizedCost")
    # print(summary)
    # print(buffer)

    # New Method with 2 example jsons
    summary, buffer, cost_dict = report_cost(None, None, "UnblendedCost", example_result, yesterday="2025-07-04", new_method=True)
    print(summary)
    print(buffer)
    # slack_hook_url = os.environ.get('SLACK_WEBHOOK_URL')
    # publish_slack(slack_hook_url, summary, buffer)
    # assert "{0:.2f}".format(cost_dict.get("total", 0.0)) == "286.37", f'{cost_dict.get("total"):,.2f} != 286.37'
    # summary, buffer, cost_dict = report_cost(None, None, "UnblendedCost", example_result2, yesterday="2025-07-04", new_method=True)
    # assert "{0:.2f}".format(cost_dict.get("total", 0.0)) == "21.45", f'{cost_dict.get("total"):,.2f} != 21.45'

    # Old Method with same jsons (will fail)
    # summary, buffer, cost_dict = report_cost(None, None, "UnblendedCost", example_result, yesterday="2025-07-04", new_method=False)
    # assert "{0:.2f}".format(cost_dict.get("total", 0.0)) == "286.37", f'{cost_dict.get("total"):,.2f} != 286.37'
    # summary, buffer, cost_dict = report_cost(None, None, "UnblendedCost", example_result2, yesterday="2025-07-04", new_method=False)
    # assert "{0:.2f}".format(cost_dict.get("total", 0.0)) == "21.45", f'{cost_dict.get("total"):,.2f} != 21.45'
