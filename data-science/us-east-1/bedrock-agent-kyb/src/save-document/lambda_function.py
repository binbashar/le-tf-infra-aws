import json
import os
from datetime import datetime

OUTPUT_BUCKET = os.environ['OUTPUT_BUCKET']

def lambda_handler(event, context):
    """Mock Bedrock Agent action group handler for saving processed documents"""
    print(f"[DEBUG] SaveDocument - Received event: {json.dumps(event)}")

    message_version = event.get('messageVersion', '1.0')
    action_group = event['actionGroup']
    api_path = event['apiPath']
    http_method = event['httpMethod']

    session_attrs = event.get('sessionAttributes', {})
    customer_id = session_attrs.get('customer_id')
    print(f"[DEBUG] SaveDocument - customer_id from session: {customer_id}")

    if not customer_id:
        print(f"[ERROR] SaveDocument - Missing customer_id in session attributes")
        return create_response(
            message_version, action_group, api_path, http_method,
            400, {'error': 'customer_id required in session attributes'}
        )

    # Parse request body for document data
    parameters = parse_request_body(event)
    print(f"[DEBUG] SaveDocument - Parsed parameters: {list(parameters.keys())}")

    # Agent sends 'content' parameter with the document data
    document_data = parameters.get('content')
    document_key = parameters.get('document_key', '')

    if not document_data:
        print(f"[ERROR] SaveDocument - Missing content parameter")
        return create_response(
            message_version, action_group, api_path, http_method,
            400, {'error': 'content parameter required'}
        )

    print(f"[DEBUG] SaveDocument - document_key suggested: {document_key}")

    # Parse document_data if it's a JSON string
    if isinstance(document_data, str):
        try:
            document_data = json.loads(document_data)
            print(f"[DEBUG] SaveDocument - Parsed document_data from JSON string")
        except json.JSONDecodeError as e:
            print(f"[ERROR] SaveDocument - Failed to parse document_data: {e}")
            return create_response(
                message_version, action_group, api_path, http_method,
                400, {'error': f'Invalid document_data JSON: {str(e)}'}
            )

    print(f"[DEBUG] SaveDocument - Document data type: {type(document_data)}")
    if isinstance(document_data, dict):
        print(f"[DEBUG] SaveDocument - Document data fields: {list(document_data.keys())}")

    # Mock: Simulate successful S3 save
    timestamp = datetime.utcnow()
    timestamp_str = timestamp.strftime('%Y%m%d_%H%M%S')
    s3_key = f"results/{customer_id}/{timestamp_str}.json"

    print(f"[DEBUG] SaveDocument - MOCK: Simulating save to s3://{OUTPUT_BUCKET}/{s3_key}")
    print(f"[DEBUG] SaveDocument - MOCK: Would save {len(json.dumps(document_data))} bytes")

    response_body = {
        'success': True,
        'message': 'Document saved successfully (MOCK)',
        'customer_id': customer_id,
        's3_location': {
            'bucket': OUTPUT_BUCKET,
            'key': s3_key,
            'uri': f's3://{OUTPUT_BUCKET}/{s3_key}'
        },
        'timestamp': timestamp.isoformat(),
        'mock': True
    }

    print(f"[DEBUG] SaveDocument - Returning success response (MOCK)")

    return create_response(
        message_version, action_group, api_path, http_method,
        200, response_body
    )

def parse_request_body(event):
    """Parse parameters from Bedrock Agent request body"""
    parameters = {}

    # Handle GET-style parameters
    if 'parameters' in event and isinstance(event['parameters'], list):
        for param in event['parameters']:
            if isinstance(param, dict) and 'name' in param:
                parameters[param['name']] = param.get('value', '')

    # Handle POST-style requestBody
    if 'requestBody' in event and isinstance(event['requestBody'], dict):
        content = event['requestBody'].get('content', {})

        if 'application/json' in content:
            json_content = content['application/json']

            # Handle properties list
            if isinstance(json_content, dict) and 'properties' in json_content:
                properties = json_content['properties']
                if isinstance(properties, list):
                    for prop in properties:
                        if isinstance(prop, dict):
                            prop_name = prop.get('name')
                            prop_value = prop.get('value')
                            if prop_name and prop_value is not None:
                                parameters[prop_name] = prop_value

    print(f"[DEBUG] Extracted parameters: {list(parameters.keys())}")
    return parameters

def create_response(message_version, action_group, api_path, http_method, status_code, body):
    """Create Bedrock Agent response format"""
    return {
        'messageVersion': message_version,
        'response': {
            'actionGroup': action_group,
            'apiPath': api_path,
            'httpMethod': http_method,
            'httpStatusCode': status_code,
            'responseBody': {
                'application/json': {
                    'body': json.dumps(body, default=str)
                }
            }
        }
    }
