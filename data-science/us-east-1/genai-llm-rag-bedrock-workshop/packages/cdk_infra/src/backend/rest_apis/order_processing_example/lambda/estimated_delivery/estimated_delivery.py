# Copyright Amazon.com and its affiliates; all rights reserved.
# SPDX-License-Identifier: LicenseRef-.amazon.com.-AmznSL-1.0
# Licensed under the Amazon Software License  https://aws.amazon.com/asl/

import json
from datetime import datetime, timedelta

def handler(event, context):
    # Parse the order ID and zipcode from the request path
    request = json.loads(event['body'])
    #order_id = request['orderId']
    zipcode = request['zipcode']

    try:
        cost = next((zipCodeData for zipCodeData in zipcodeTable() if zipCodeData['zipcode'] == zipcode), None)
        if cost and len(cost) > 0:
            estimated_delivery_date = datetime.now() + timedelta(days=1)
            # Return the ETA response
            return {
                'statusCode': 200,
                'body': json.dumps({
                    'zipcode': zipcode,
                    'estimated_delivery_date': estimated_delivery_date.strftime('%Y-%m-%d')
                })
            }
        else:
            # Return a 404 error if the zipcode is not found
            return {
                'statusCode': 404,
                'body': json.dumps({'error': 'Zipcode not found'})
            }
    except Exception as e:
        # Return an error response
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }

def costEstimates(zipcode: str):
    cost = [zip for zip in zipcodeTable() if zip.zipcode == zipcode] 
    if cost:
        return cost[0]
    else:
        return 0
    
def zipcodeTable():
    return [
    {
        "zipcode": "90001",
        "city": "Los Angeles",
        "state": "CA",
        "estimatedShippingCost": 8.99
    },
    {
        "zipcode": "60007",
        "city": "Chicago",
        "state": "IL",
        "estimatedShippingCost": 7.49
    },
    {
        "zipcode": "77001",
        "city": "Houston",
        "state": "TX",
        "estimatedShippingCost": 6.99
    },
    {
        "zipcode": "33101",
        "city": "Miami",
        "state": "FL",
        "estimatedShippingCost": 9.99
    },
    {
        "zipcode": "98101",
        "city": "Seattle",
        "state": "WA",
        "estimatedShippingCost": 10.49
    },
    {
        "zipcode": "10001",
        "city": "New York",
        "state": "NY",
        "estimatedShippingCost": 8.49
    },
    {
        "zipcode": "75201",
        "city": "Dallas",
        "state": "TX",
        "estimatedShippingCost": 6.99
    },
    {
        "zipcode": "94101",
        "city": "San Francisco",
        "state": "CA",
        "estimatedShippingCost": 9.99
    },
    {
        "zipcode": "60601",
        "city": "Chicago",
        "state": "IL",
        "estimatedShippingCost": 7.49
    },
    {
        "zipcode": "77002",
        "city": "Houston",
        "state": "TX",
        "estimatedShippingCost": 6.99
    }
    ]