# You may need to install some of the following packages
import requests
import boto3
import json
from botocore.auth import SigV4Auth
from botocore.awsrequest import AWSRequest
from botocore.credentials import RefreshableCredentials, get_credentials
from botocore.session import get_session

def make_signed_post_request(url, payload, region):
    session = boto3.session.Session()
    credentials = session.get_credentials()
    service = 'execute-api'

    request = AWSRequest(method='POST', url=url, data=payload, headers={'Content-Type': 'application/json'})

    SigV4Auth(credentials, service, region).add_auth(request)

    response = requests.post(url, data=payload, headers=request.headers)

    return response

# =============================================================================
# IMPORTANT
# -----------------------------------------------------------------------------
# Adjust the following as necessary:
#   - url: get the actual one from API Gateway Invoke URL
#   - region: this should match the region where you provisioned the AWS resources
#   - payload: in this case the key field it's "order_id"
# =============================================================================
url     = 'https://abcdef0123.execute-api.us-east-1.amazonaws.com/v1/externalCallback'    # Update this !!!
region  = 'us-east-1'
payload = json.dumps({
  "order_id": "order-123",
  "task_type": "ORDER_SHIPPING_SERVICE",
  "task_status": "SUCCEEDED",
  "task_output": {
    "shipping_status": "PROCESSING",
    "tracking_number": "1ZU2B3C4D5"
  }
})

response = make_signed_post_request(url, payload, region)
print(response.status_code)
print(response.text)
