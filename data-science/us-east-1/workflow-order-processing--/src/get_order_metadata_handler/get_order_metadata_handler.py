import boto3
import json
import os

def get_order_metadata(event, context):
    order_table = os.getenv('ORDER_TABLE')
    order_id = event['order_id']
    dynamo_client = boto3.client('dynamodb')

    return __get_order_contents(dynamo_client, order_table, order_id)


def __get_order_contents(dynamo_client, order_table, order_id):
    resp = dynamo_client.get_item(
        TableName=order_table,
        Key={
            'order_id': {
                'S': order_id
            }
        }
    )

    return {item_name: item_quantity for (item_name, item_quantity) in resp['Item']['order_contents']['M'].items()}
