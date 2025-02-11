# Copyright Amazon.com and its affiliates; all rights reserved.
# SPDX-License-Identifier: LicenseRef-.amazon.com.-AmznSL-1.0
# Licensed under the Amazon Software License  https://aws.amazon.com/asl/

from response_utils import create_api_response
from error_utils import get_error_response

def get_property_value(properties, prop_name, error_code, example_type, event):
    """
    Helper function to extract property value from request properties with error handling
    
    Args:
        properties (list): List of property dictionaries from the request
        prop_name (str): Name of the property to extract
        error_code (str): Error code to use if property is missing
        example_type (str): Type of example to include in error response
        event (dict): Original event object for creating response
        
    Returns:
        str: Property value if found
        dict: Error response if property is missing or invalid
    """
    prop = next((p for p in properties if p.get('name') == prop_name), None)
    if prop is None or 'value' not in prop:
        return create_api_response(
            event,
            400,
            get_error_response(error_code, example_type=example_type)
        )
    return prop['value']