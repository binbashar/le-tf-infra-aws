import json
import os
import boto3

PROCESSING_BUCKET = os.environ['PROCESSING_BUCKET']

s3_client = boto3.client('s3')

def lambda_handler(event, _context):
    """Bedrock Agent action group handler"""

    message_version = event.get('messageVersion', '1.0')
    action_group = event['actionGroup']
    api_path = event['apiPath']
    http_method = event['httpMethod']

    session_attrs = event.get('sessionAttributes', {})
    customer_id = session_attrs.get('customer_id')

    parameters = {}
    if 'parameters' in event and isinstance(event['parameters'], list):
        for param in event['parameters']:
            if isinstance(param, dict) and 'name' in param:
                parameters[param['name']] = param.get('value', '')

    output_type = parameters.get('output_type', 'Standard')

    if not customer_id:
        return create_response(
            message_version, action_group, api_path, http_method,
            400, json.dumps({'error': 'customer_id required'})
        )

    if output_type not in ['Custom', 'Standard']:
        return create_response(
            message_version, action_group, api_path, http_method,
            400, json.dumps({'error': 'output_type must be Custom or Standard'})
        )

    prefix = f"standard/{customer_id}/"
    documents = list_customer_documents(prefix, output_type)

    response_body = {
        'customer_id': customer_id,
        'output_type': output_type,
        'documents': documents,
        'document_count': len(documents)
    }

    return create_response(
        message_version, action_group, api_path, http_method,
        200, json.dumps(response_body)
    )

def list_customer_documents(prefix, output_type):
    """List and read BDA result.json files from processing bucket"""
    documents = []

    response = s3_client.list_objects_v2(
        Bucket=PROCESSING_BUCKET,
        Prefix=prefix
    )

    objects = response.get('Contents', [])

    output_dir = 'custom_output' if output_type == 'Custom' else 'standard_output'

    result_keys = [
        obj['Key'] for obj in objects
        if f"/{output_dir}/" in obj['Key'] and obj['Key'].endswith('/result.json')
    ]

    for key in result_keys:
        try:
            obj = s3_client.get_object(Bucket=PROCESSING_BUCKET, Key=key)
            content = json.loads(obj['Body'].read().decode('utf-8'))

            doc_data = {'s3_key': key, 'last_modified': obj['LastModified'].isoformat()}

            if output_type == 'Custom':
                doc_data['extraction_data'] = content.get('inference_result', {})
            else:
                document = content.get('document', {})
                representation = document.get('representation', {})
                doc_data['document_text'] = representation.get('text', '')

            documents.append(doc_data)
        except Exception:
            continue

    return documents

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
                    'body': body
                }
            }
        }
    }
