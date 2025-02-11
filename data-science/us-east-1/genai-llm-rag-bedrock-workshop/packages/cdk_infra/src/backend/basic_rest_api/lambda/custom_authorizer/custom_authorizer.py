# Copyright Amazon.com and its affiliates; all rights reserved.
# SPDX-License-Identifier: LicenseRef-.amazon.com.-AmznSL-1.0
# Licensed under the Amazon Software License  https://aws.amazon.com/asl/

import re
from aws_lambda_powertools import Logger
from aws_lambda_powertools.utilities.typing import LambdaContext
from aws_lambda_powertools.logging import correlation_paths

logger = Logger(use_rfc3339=True)


class CustomAuthorizerError(Exception):
    """Base class for custom authorizer exceptions."""
    pass


class InvalidTokenError(CustomAuthorizerError):
    """Raised when the provided token is invalid."""
    pass


class UnauthorizedError(CustomAuthorizerError):
    """Raised when the provided token is not authorized."""
    pass


def generate_policy(principal_id, effect, resource):
    """
    Generate an authorization policy document for an AWS API Gateway custom authorizer.

    Args:
        principal_id (str): The identifier of the principal (e.g., user, role, or service) being authorized.
        effect (str): The effect of the policy, either 'Allow' or 'Deny'.
        resource (str): The Amazon Resource Name (ARN) of the API method being accessed.

    Returns:
        dict: The authorization policy document.

    Raises:
        ValueError: If the `effect` argument is not 'Allow' or 'Deny'.
    """

    if effect not in ['Allow', 'Deny']:
        raise ValueError(
            "The 'effect' argument must be either 'Allow' or 'Deny'.")

    policy = {
        'principalId': principal_id,
        'policyDocument': {
            'Version': '2012-10-17',
            'Statement': [
                {
                    'Action': 'execute-api:Invoke',
                    'Effect': effect,
                    'Resource': resource
                }
            ]
        }
    }
    return policy


@logger.inject_lambda_context(log_event=True, correlation_id_path=correlation_paths.API_GATEWAY_REST)
def lambda_handler(event: dict, context: LambdaContext):

    # Get the token from the Authorization header
    auth_header = event['authorizationToken']
    logger.info(f'Authorization Header: {auth_header}')

    # Use a regular expression to extract the token value
    token_value = (re.search(r'Bearer (.+)$', auth_header)).group(1)
    logger.info(f'Authorization Token Value: {token_value}')

    # Determine whether a client should be granted or denied access to the API method based on token value
    # Valid values: allow, deny, unauthorized.
    logger.info('Determining authorization policy...')
    match token_value:
        case 'allow':
            return generate_policy('detector-user', 'Allow', event['methodArn'])
        case 'deny':
            return generate_policy('detector-user', 'Deny', event['methodArn'])
        case 'unauthorized':
            raise UnauthorizedError(f'Token {token_value} is not authorized.')
        case _:
            raise InvalidTokenError(f'The provided token {token_value} is invalid.')
