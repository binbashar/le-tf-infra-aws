# Copyright Amazon.com and its affiliates; all rights reserved.
# SPDX-License-Identifier: LicenseRef-.amazon.com.-AmznSL-1.0
# Licensed under the Amazon Software License  https://aws.amazon.com/asl/

import json

def handler(event, context):
    request = json.loads(event['body'])
    # Parse the order ID from the request path
    order_id = int(request['orderId'])

    # Update the order status to 'cancelled'
    


    # Return a success response
    return {
        'statusCode': 200,
        'body': json.dumps({'message': f'Order {order_id} cancelled successfully'})
    }
    
