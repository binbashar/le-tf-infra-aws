# Copyright Amazon.com and its affiliates; all rights reserved.
# SPDX-License-Identifier: LicenseRef-.amazon.com.-AmznSL-1.0
# Licensed under the Amazon Software License  https://aws.amazon.com/asl/

import json

# Mock order data
orders = [
    {'id': 1, 'status': 'pending'},
    {'id': 2, 'status': 'shipped'},
    {'id': 3, 'status': 'delivered'},
    {'id': 4, 'status': 'cancelled'},
]

def handler(event, context):
    # Parse the order ID from the request path
    order_id = int(event['queryStringParameters']['orderId'])

    # Find the order with the given ID
    order = next((order for order in orders if order['id'] == order_id), None)

    if order:
        # Return the order status
        response = {
            'statusCode': 200,
            'body': json.dumps(order)
        }
    else:
        # Return a 404 error if the order is not found
        response = {
            'statusCode': 404,
            'body': json.dumps({'error': 'Order not found'})
        }

    return response