import boto3
import json
import os


def sns_callback(event, context):
    payload_event_key = os.getenv('PAYLOAD_EVENT_KEY')
    callback_table = os.getenv('CALLBACK_TABLE')
    task_type = os.getenv('TASK_TYPE')
    sns_topic_arn = os.getenv('SNS_TOPIC_ARN')

    order_id = event['input']['order_id']
    order_contents = event['input']['order_contents']
    task_token = event['token']
    payload = event['input'][payload_event_key]

    dynamo_client = boto3.client('dynamodb')
    sns_client = boto3.client('sns')

    __create_callback_task(dynamo_client, callback_table, task_token, order_id, task_type)

    __send_sns_messsage(sns_client, sns_topic_arn, order_id, payload)


def __send_sns_messsage(sns_client, topic_arn, order_id, payload):
    message = json.dumps({
        'order_id': order_id,
        'payload': payload
    })
    sns_client.publish(TopicArn=topic_arn, Message=message)


def __create_callback_task(dynamo_client, callback_table, task_token, order_id, task_type):
    dynamo_client.put_item(
        TableName=callback_table,
        Item={
            'task_token': {
                'S': task_token
            },
            'task_type': {
                'S': task_type
            },
            'order_id': {
                'S': order_id
            },
            'task_status': {
                'S': 'CREATED'
            }
        }
    )