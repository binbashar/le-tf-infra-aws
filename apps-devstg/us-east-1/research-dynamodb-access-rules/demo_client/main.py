import hmac
import hashlib
import base64
import json
from decimal import Decimal

import boto3
from botocore.exceptions import ClientError

# --- Configuration ---
REGION = "us-east-1"
IDENTITY_POOL_ID = "us-east-1:f49f5c58-992a-4562-a286-c5b3565c6d26"
COGNITO_CLIENT_ID = "1m3lphbh7hfq2g8o7ha06vojjg"
USER_POOL_ID = "us-east-1_2cs4se6hE"
USER_POOL_PROVIDER_NAME = "cognito-idp.{}.amazonaws.com/{}".format(REGION, USER_POOL_ID) # e.g., cognito-idp.us-east-1.amazonaws.com/us-east-1_XXXXX
CLIENT_SECRET = "pupm860lddvp9hbi5hkuaptb6mvcd88ne1v4omhms4aji4aukja"
DYNAMODB_TABLE_NAME = "bb-apps-devstg-bb-devstg-research-dynamodb"
USER_EMAIL_1="SaulGoodman@hhm.com"
USER_PWD_1="superSAFE.password.for/the$sake-of%demo9"
USER_EMAIL_2="Chuck@hhm.com"
USER_PWD_2="sdflksjKJLjs.password.for/the$sake-of%demo9"


def decimal_serializer(obj):
    if isinstance(obj, Decimal):
        return str(obj)
    raise TypeError("Type not serializable")

def create_user_without_force_change(username: str, email: str, temporary_password: str):
    """
    Creates a user in Cognito and sets their state to CONFIRMED,
    bypassing the FORCE_CHANGE_PASSWORD requirement.
    """
    client = boto3.client('cognito-idp', region_name=REGION)

    try:
        response = client.admin_create_user(
            UserPoolId=USER_POOL_ID,
            Username=username,

            # --- Key Parameter 1: Set a temporary password ---
            TemporaryPassword=temporary_password,

            # --- Key Parameter 2: Auto-confirm the user status ---
            MessageAction='SUPPRESS', # Prevents sending an invite/temporary password email

            # --- Key Parameter 3: Set status to Confirmed ---
            # This is crucial for users who shouldn't have to verify (like migration or backend users)
            # Cognito automatically confirms the user when MessageAction='SUPPRESS' is used
            # with a TemporaryPassword.

            UserAttributes=[
                {'Name': 'email', 'Value': email},
                {'Name': 'email_verified', 'Value': 'true'}, # Set email as verified
            ]
        )

        # Optional: Set the user's permanent password immediately after creation
        # This moves the user from "Force Change Password" or "Temporary" status to "Permanent"
        client.admin_set_user_password(
            UserPoolId=USER_POOL_ID,
            Username=username,
            Password=temporary_password,
            Permanent=True # Set the user's temporary password as their permanent one
        )

        print(f"✅ User {username} created and status set to permanent password.")
        return response

    except client.exceptions.UsernameExistsException:
        print(f"❌ User {username} already exists.")
    except Exception as e:
        print(f"❌ Error creating user: {e}")

def calculate_secret_hash(username):
    """
    Calculates the SECRET_HASH for Cognito authentication flows.
    The hash is HMAC(SHA256(CLIENT_SECRET), USERNAME + CLIENT_ID)
    """
    message = bytes(username + COGNITO_CLIENT_ID, 'utf-8')
    key = bytes(CLIENT_SECRET, 'utf-8')

    # Generate the HMAC-SHA256 hash
    digester = hmac.new(key, message, hashlib.sha256)

    # Encode the resulting hash to Base64 (standard for Cognito)
    secret_hash = base64.b64encode(digester.digest()).decode()
    return secret_hash

def sign_in_and_get_tokens(username,pwd):
    """
    Signs in a user to the Cognito User Pool (using Admin flow for simplicity)
    and returns the authentication tokens.
    """
    secret_hash = calculate_secret_hash(username)

    client = boto3.client('cognito-idp', region_name=REGION)

    try:
        response = client.admin_initiate_auth(
            UserPoolId=USER_POOL_ID,
            ClientId=COGNITO_CLIENT_ID,
            AuthFlow='ADMIN_NO_SRP_AUTH', # Simple password flow, requires Admin secret if used client-side
            AuthParameters={
                'USERNAME': username,
                'PASSWORD': pwd,
                'SECRET_HASH': secret_hash
            }
        )


        # The result holds the tokens
        auth_result = response.get('AuthenticationResult', {})

        return {
            'id_token': auth_result.get('IdToken'),
            'access_token': auth_result.get('AccessToken'),
            'refresh_token': auth_result.get('RefreshToken')
        }

    except client.exceptions.NotAuthorizedException as e:
        print(f"Authentication failed: Invalid username or password: {e}")
        return None
    except Exception as e:
        print(f"An error occurred during sign-in: {e}")
        return None

# --- Usage Example ---
# tokens = sign_in_and_get_tokens("user@example.com", "MySecureP@ss123", "...", "...", "us-east-1")
# if tokens:
#     ID_TOKEN = tokens['id_token'] # This is the token passed to the Identity Pool

def get_federated_credentials(id_token: str):
    """
    Exchanges a Cognito User Pool ID Token for temporary AWS credentials
    via the Cognito Identity Pool (Federated Identities).
    """
    try:
        # 1. Initialize Cognito Identity client
        cognito_identity_client = boto3.client('cognito-identity', region_name=REGION)

        print(f'Using USER_POOL_PROVIDER_NAME={USER_POOL_PROVIDER_NAME}')
        # 2. Get Identity ID (The 'sub' value used as the DynamoDB PK)
        get_id_response = cognito_identity_client.get_id(
            IdentityPoolId=IDENTITY_POOL_ID,
            Logins={
                USER_POOL_PROVIDER_NAME: id_token
            }
        )
        identity_id = get_id_response['IdentityId']
        print(f"✅ Identity ID (DynamoDB PK): {identity_id}")
    except ClientError as e:
        print(f"❌ Error retrieving identity id: {e}")
        return None, None

    try:
        # 3. Get Temporary Credentials
        credentials_response = cognito_identity_client.get_credentials_for_identity(
            IdentityId=identity_id,
            Logins={
                USER_POOL_PROVIDER_NAME: id_token
            }
        )

        return identity_id, credentials_response['Credentials']

    except ClientError as e:
        print(f"❌ Error getting credentials for identity: {e}")
        return None, None

def add_items_to_dynamo(identity_id: str, credentials: dict):
    """
    Instantiates a DynamoDB client using the temporary credentials and attempts operations.
    """
    try:
        # Instantiate the DynamoDB client using the temporary credentials
        dynamodb = boto3.resource('dynamodb',
            region_name=REGION,
            aws_access_key_id=credentials['AccessKeyId'],
            aws_secret_access_key=credentials['SecretKey'],
            aws_session_token=credentials['SessionToken']
        )

        table = dynamodb.Table(DYNAMODB_TABLE_NAME)
    except Exception as e:
        print(f"❌ FAILURE: Creating access to table: {e}")

    # ----------------------------------------------------
    # A. SUCCESSFUL OPERATION: Accessing own data (userId = PK)
    # ----------------------------------------------------
    print("\n--- A. Test Successful Write (Creating own Movie) ---")

    # The 'userId' (PK) in the item matches the 'identity_id' from the credentials.
    movies_item = [
        {
        'userId': identity_id,
        'entityId': 'MOVIE#T800',
        'title': 'The Terminator',
        'rating': 5
        },
        {
        'userId': identity_id,
        'entityId': 'MOVIE#NEO',
        'title': 'The Matrix',
        'rating': 9
        },
        {
        'userId': identity_id,
        'entityId': 'MOVIE#JC',
        'title': 'The Man From Earth',
        'rating': 10
        }
    ]

    try:
        for movie_item in movies_item:
            table.put_item(Item=movie_item)
        print("✅ SUCCESS: PutItem successful. Access control approved the write.")
    except ClientError as e:
        print(f"❌ FAILURE: PutItem failed unexpectedly: {e.response['Error']['Code']}")

def read_items_from_dynamo(identity_id: str, credentials: dict):
    """
    Instantiates a DynamoDB client using the temporary credentials and attempts operations.
    """
    try:
        # Instantiate the DynamoDB client using the temporary credentials
        dynamodb = boto3.resource('dynamodb',
            region_name=REGION,
            aws_access_key_id=credentials['AccessKeyId'],
            aws_secret_access_key=credentials['SecretKey'],
            aws_session_token=credentials['SessionToken']
        )

        table = dynamodb.Table(DYNAMODB_TABLE_NAME)
    except Exception as e:
        print(f"❌ FAILURE: Creating access to table: {e}")

    try:
        # Successful Query for own data (PK is specified)
        response = table.query(
            KeyConditionExpression=boto3.dynamodb.conditions.Key('userId').eq(identity_id) &
                                 boto3.dynamodb.conditions.Key('entityId').begins_with('MOVIE#')
        )
        print(f"✅ SUCCESS: Query successful. Found {len(response['Items'])} private movie item(s).")
        print(json.dumps(response['Items'],indent=1,default=decimal_serializer))
    except ClientError as e:
        print(f"❌ FAILURE: QueryItem failed unexpectedly: {e.response['Error']['Code']}")


#     # ----------------------------------------------------
#     # B. FAILED OPERATION: Attempting to access another user's data
#     # ----------------------------------------------------
#     print("\n--- B. Test Failed Read (Accessing other user's data) ---")
#
#     # Attempting to read an item with a different Partition Key (userId)
#     other_user_id = 'different-user-id'
#
#     try:
#         table.get_item(Key={'userId': other_user_id, 'entityId': 'PROFILE'})
#         print("❌ CRITICAL FAILURE: GetItem unexpectedly succeeded on another user's data.")
#     except ClientError as e:
#         if e.response['Error']['Code'] == 'AccessDeniedException':
#             print("✅ SUCCESS: GetItem failed with 'AccessDeniedException'. IAM policy enforced security.")
#         else:
#             print(f"❌ FAILURE: GetItem failed with unexpected error: {e.response['Error']['Code']}")

# --- Simulation ---

print('-- CREATING USERS --')
create_user_without_force_change(USER_EMAIL_1, USER_EMAIL_1, USER_PWD_1)
create_user_without_force_change(USER_EMAIL_2, USER_EMAIL_2, USER_PWD_2)


def test_the_thing(username,userpwd,use_identity=None):
    # --- Login ---
    identity_id = None
    print('------------------------------------')
    print(f'-- FULL TEST FOR USER {username} --')
    print('------------------------------------')
    print('-- GETTING TOKENS --')
    print('(note this should be done in a best way, this is aimed to a demo only!!!)')
    tokens = sign_in_and_get_tokens(username,userpwd)
    if tokens and 'id_token' in tokens and tokens['id_token']:
        print("✅ SUCCESS: Logged in!")
        ID_TOKEN = tokens['id_token'] # This is the token passed to the Identity Pool

        # --- Get temp creds ---
        print('-- GETTING TEMP CREDS --')
        identity_id, temporary_credentials = get_federated_credentials(ID_TOKEN)
        print("✅ SUCCESS: Got Creds!")

        # --- test it ---
        print('-- ACCESSING DYNAMO --')
        if identity_id and temporary_credentials:
            add_items_to_dynamo(identity_id, temporary_credentials)
            print("✅ SUCCESS: tested Dynamo write!")
        else:
            print("❌ FAILURE: Can not write dynamo")

        if (identity_id or use_identity is not None) and temporary_credentials:
            if use_identity is not None:
                identity_id = use_identity
                print('    *************************************')
                print('    TESTING WITH WRONG ID, IT SHOULD FAIL')
                print('    *************************************')
            read_items_from_dynamo(identity_id, temporary_credentials)
            print("✅ SUCCESS: tested Dynamo read!")

    else:
        print("❌ FAILURE: Can not login")
    return identity_id

identity1_id = test_the_thing(USER_EMAIL_1,USER_PWD_1)
identity2_id = test_the_thing(USER_EMAIL_2,USER_PWD_2)
identity2_id = test_the_thing(USER_EMAIL_2,USER_PWD_2,use_identity=identity1_id)
