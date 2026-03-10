import json
import random

def lambda_handler(event, _context):
    """Bedrock Agent action group handler for sanctions checking"""
    print(f"[DEBUG] Received event: {json.dumps(event)}")

    message_version = event.get('messageVersion', '1.0')
    action_group = event['actionGroup']
    api_path = event['apiPath']
    http_method = event['httpMethod']

    session_attrs = event.get('sessionAttributes', {})
    customer_id = session_attrs.get('customer_id')
    print(f"[DEBUG] customer_id from session: {customer_id}")

    parameters = {}
    if 'parameters' in event and isinstance(event['parameters'], list):
        for param in event['parameters']:
            if isinstance(param, dict) and 'name' in param:
                parameters[param['name']] = param.get('value', '')

    name = parameters.get('name')
    surname = parameters.get('surname')
    document_id = parameters.get('document_id')

    if not document_id and not (name and surname):
        return create_response(
            message_version, action_group, api_path, http_method,
            400, {'error': 'Either document_id or name+surname required'}
        )

    sanctions_data = check_sanctions(name, surname, document_id)

    return create_response(
        message_version, action_group, api_path, http_method,
        200, sanctions_data
    )

def check_sanctions(name, surname, document_id):
    """Check sanctions status - DEMO: returns mocked random data"""
    if document_id:
        query_type = 'document_id'
        query_value = document_id
    else:
        query_type = 'name'
        query_value = f"{name} {surname}"

    return get_mocked_sanctions_data(query_type, query_value)

def get_mocked_sanctions_data(query_type, query_value):
    """Generate mocked sanctions data for demo purposes

    To replace with real API: modify this function to call external service
    Example:
        response = requests.post(API_ENDPOINT, json={...})
        return response.json()
    """
    random.seed(hash(query_value) % 10000)

    scenarios = [
        {'num_sanctions': 0, 'pep_score': 0.1},
        {'num_sanctions': 0, 'pep_score': 0.3},
        {'num_sanctions': 0, 'pep_score': 0.5},
        {'num_sanctions': 0, 'pep_score': 0.8},
        {'num_sanctions': 1, 'pep_score': 0.2},
        {'num_sanctions': 2, 'pep_score': 0.9},
    ]

    result = random.choice(scenarios)

    return {
        'num_sanctions': result['num_sanctions'],
        'pep_score': result['pep_score'],
        'query_type': query_type,
        'query_value': query_value
    }

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
