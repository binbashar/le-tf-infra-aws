# Copyright Amazon.com and its affiliates; all rights reserved.
# SPDX-License-Identifier: LicenseRef-.amazon.com.-AmznSL-1.0
# Licensed under the Amazon Software License  https://aws.amazon.com/asl/

import json
import random

products = [
    {"id": 1, "name": "ASTR-WD101", "category": "dress"},
    {"id": 2, "name": "ASTR-WD349", "category": "dress"},
    {"id": 3, "name": "ASTR-WD217", "category": "dress"},
    {"id": 4, "name": "ASTR-WD428", "category": "dress"},
    {"id": 5, "name": "ASTR-WD159", "category": "dress"},
    {"id": 6, "name": "ASTR-WD501", "category": "dress"},
    {"id": 7, "name": "ASTR-WD273", "category": "dress"},
    {"id": 8, "name": "ASTR-WD386", "category": "dress"},
    {"id": 9, "name": "ASTR-WD115", "category": "dress"},
    {"id": 10, "name": "ASTR-WD457", "category": "dress"},
    {"id": 11, "name": "ASTR-WD317", "category": "dress"},
    {"id": 12, "name": "ASTR-WD442", "category": "dress"},
    {"id": 13, "name": "ASTR-WD171", "category": "dress"},
    {"id": 14, "name": "ASTR-WD513", "category": "dress"},
    {"id": 15, "name": "ASTR-WD285", "category": "dress"},
    {"id": 16, "name": "ASTR-WD398", "category": "dress"},
    {"id": 17, "name": "ASTR-WD127", "category": "dress"},
    {"id": 18, "name": "ASTR-WD469", "category": "dress"},
    {"id": 19, "name": "ASTR-WD329", "category": "dress"},
    {"id": 20, "name": "ASTR-WD454", "category": "dress"},
    {"id": 21, "name": "ASTR-WD183", "category": "dress"},
    {"id": 22, "name": "ASTR-WD525", "category": "dress"},
    {"id": 23, "name": "ASTR-WD297", "category": "dress"},
    {"id": 24, "name": "ASTR-WD410", "category": "dress"},
    {"id": 25, "name": "ASTR-WD139", "category": "dress"},
    {"id": 26, "name": "ASTR-WD481", "category": "dress"},
    {"id": 27, "name": "ASTR-WD309", "category": "dress"},
    {"id": 28, "name": "ASTR-WD422", "category": "dress"},
    {"id": 29, "name": "ASTR-WD151", "category": "dress"},
    {"id": 30, "name": "ASTR-WD493", "category": "dress"}
]

def handler(event, context):
    # Parse the search query from the request path
    request = json.loads(event['body'])
    search_query = request['query']

    # Get the search query from the request
    #query = event.get('queryStringParameters', {}).get('q', '')

    # Filter products based on the search query
    #filtered_products = [product for product in products if search_query.lower() in product['name'].lower()]
    filtered_products = random.sample(products, 10)

    # Extract product IDs from the filtered products
    product_ids = [product['name'] for product in filtered_products]

    # Return the list of product IDs
    response = {
        "statusCode": 200,
        "headers": {
            "Content-Type": "application/json"
        },
        "body": json.dumps(product_ids)
    }

    return response

