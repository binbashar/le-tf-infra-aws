import json
import os
import boto3


def external_callback(event, context):
    table_name = os.getenv('CALLBACK_TABLE')
    order_id = event['order_id']
    task_type = event['task_type']
    task_status = event['task_status']
    task_output = event.get('task_output', None)
    task_error = event.get('task_error', None)

    dynamo_client = boto3.client('dynamodb')

    try:
        token = __get_token(dynamo_client, table_name, order_id, task_type)

        if task_status == 'SUCCEEDED':
            __set_task_success(token, task_output)
            __update_task_status(dynamo_client, table_name, order_id, task_type, 'SUCCEEDED')
        else:
            __set_task_failure(token, task_error)
            __update_task_status(dynamo_client, table_name, order_id, task_type, 'FAILED')

    except Exception as e:
        raise Exception('Internal Error: {}'.format(str(e)))


def __get_token(dynamo_client, table_name, order_id, task_type):
    resp = dynamo_client.get_item(
        TableName=table_name,
        Key={
            'order_id': {
                'S': order_id
            },
            'task_type': {
                'S': task_type
            }
        }
    )
    return resp['Item']['task_token']['S']


def __set_task_success(token, output):
    sf_client = boto3.client('stepfunctions')
    sf_client.send_task_success(
        taskToken=token,
        output=json.dumps(output)
    )


def __set_task_failure(token, error):
    sf_client = boto3.client('stepfunctions')

    sf_client.send_task_failure(
        taskToken=token,
        error=json.dumps(error)
    )


def __update_task_status(dynamo_client, table_name, order_id, task_type, task_status):
    dynamo_client.update_item(
        TableName=table_name,
        Key={
            'order_id': {
                'S': order_id
            },
            'task_type': {
                'S': task_type
            }
        },
        UpdateExpression="set task_status = :ts",
        ExpressionAttributeValues={
            ':ts': {
                'S': task_status
            }
        }
)