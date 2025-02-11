# Copyright Amazon.com and its affiliates; all rights reserved.
# SPDX-License-Identifier: LicenseRef-.amazon.com.-AmznSL-1.0
# Licensed under the Amazon Software License  https://aws.amazon.com/asl/

def create_api_response(event, http_status_code, result):
    """Create a standardized API response"""
    response_body = {
        'application/json': {
            'body': result if http_status_code == 200 else {
                'error': result.get('error', 'UNKNOWN_ERROR'),
                'message': result.get('message', 'Query execution failed'),
                'hint': result.get('hint', 'Please review and modify your query')
            }
        }
    }
    
    action_response = {
        'actionGroup': event['actionGroup'],
        'apiPath': event['apiPath'],
        'httpMethod': event['httpMethod'],
        'httpStatusCode': http_status_code,
        'responseBody': response_body
    }
    
    return {'messageVersion': '1.0', 'response': action_response}