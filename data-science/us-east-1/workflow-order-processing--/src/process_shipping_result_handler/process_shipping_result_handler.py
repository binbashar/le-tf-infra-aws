import os
import boto3


def process_shipping_result(event, context):
    shipping_info_event_key = os.getenv('SHIPPING_INFO_EVENT_KEY')
    order_table = os.getenv('ORDER_TABLE')
    order_id = event['order_id']
    shipping_info = event[shipping_info_event_key]
    tracking_number = shipping_info['tracking_number']

    dynamo_client = boto3.client('dynamodb')

    __update_tracking_number(dynamo_client, order_table, order_id, tracking_number)


def __update_tracking_number(dynamo_client, table_name, order_id, tracking_number):
    dynamo_client.update_item(
        TableName=table_name,
        Key={
            'order_id': {
                'S': order_id
            }
        },
        UpdateExpression="set tracking_number = :tn",
        ExpressionAttributeValues={
            ':tn': {
                'S': tracking_number
            }
        }
)