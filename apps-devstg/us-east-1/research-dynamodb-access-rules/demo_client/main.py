import hmac
import hashlib
import base64
import json
import os
import sys
import random
import string
from dotenv import load_dotenv
from decimal import Decimal

import boto3
from botocore.exceptions import ClientError

# --- Helper Function for Strict ENV VAR Retrieval ---
def get_required_env_var(key):
    """
    Retrieves the value of a required environment variable.
    Exits the script with an error message if the variable is not set.
    """
    value = os.environ.get(key)
    if value is None:
        print(f"❌ ERROR: Required environment variable '{key}' is not set.")
        print("Please ensure the shell script ran successfully and exported this Terraform output.")
        sys.exit(1) # Exit with a non-zero status code to indicate failure

    # Trim whitespace just in case the environment variable has leading/trailing spaces
    return value.strip()

load_dotenv()

PASSWORD_FILE = "binbash_test_passwords.json"

# --- Environment Variable Keys (Matching the Shell Script's Exported Names) ---
# The shell script converts Terraform output names to uppercase.
# e.g., dynamodb_table_name -> DYNAMODB_TABLE_NAME
ENV_DYNAMODB_TABLE_NAME = "DYNAMODB_TABLE_NAME"
ENV_IDENTITY_POOL_ID = "AWS_COGNITO_IDENTITY_POOL_ID"
ENV_COGNITO_CLIENT_ID = "AWS_COGNITO_USER_POOL_CLIENT_ID"
ENV_USER_POOL_ID = "AWS_COGNITO_USER_POOL_ID"
ENV_CLIENT_SECRET = "AWS_COGNITO_USER_POOL_CLIENT_CLIENT_SECRET"
ENV_REGION_ENDPOINT = "AWS_COGNITO_USER_POOL_ENDPOINT"

# Dynamically retrieve and enforce all variables
DYNAMODB_TABLE_NAME = get_required_env_var(ENV_DYNAMODB_TABLE_NAME)
IDENTITY_POOL_ID = get_required_env_var(ENV_IDENTITY_POOL_ID)
COGNITO_CLIENT_ID = get_required_env_var(ENV_COGNITO_CLIENT_ID)
USER_POOL_ID = get_required_env_var(ENV_USER_POOL_ID)
CLIENT_SECRET = get_required_env_var(ENV_CLIENT_SECRET)
REGION_ENDPOINT = get_required_env_var(ENV_REGION_ENDPOINT)

# Determine the region. This is often necessary for SDK calls.
# The user pool ID usually contains the region (e.g., "us-east-1_XXXXX").
# We can extract it or use a separate variable if available.
# Assuming the region is the prefix of the USER_POOL_ID (e.g., "us-east-1")
REGION = USER_POOL_ID.split('_')[0] if '_' in USER_POOL_ID else "us-east-1"
print(f"✅ REGION inferred from USER_POOL_ID: {REGION}")

USER_POOL_PROVIDER_NAME = "cognito-idp.{}.amazonaws.com/{}".format(REGION, USER_POOL_ID) # e.g., cognito-idp.us-east-1.amazonaws.com/us-east-1_XXXXX



# --- Password Generation Function (same as before) ---
def generate_strong_password(length=20):
    """
    Generates a random, strong password that:
    1. Meets common complexity requirements (upper, lower, digit, symbol).
    2. Guarantees the password starts with a letter.
    """
    if length < 12:
        length = 12

    # Define character sets
    lower = string.ascii_lowercase
    upper = string.ascii_uppercase
    digits = string.digits
    punctuation = "!@#$%^&*-+="

    # Combined sets
    letters = lower + upper
    all_chars = letters + digits + punctuation

    # 1. Start the password with a random letter (upper or lower)
    password = [random.choice(letters)]

    # 2. Ensure all required character types are present in the remaining characters
    # We already have one letter, so we only need to guarantee the remaining three types:
    required_chars = [
        random.choice(lower),
        random.choice(upper),
        random.choice(digits),
        random.choice(punctuation)
    ]

    # 3. Fill the remaining length with random choices from all sets
    remaining_length = length - len(password) - len(required_chars)

    # Combine required characters and filler
    filler_chars = required_chars + [random.choice(all_chars) for _ in range(remaining_length)]

    # 4. Shuffle the filler characters to randomize their positions
    random.shuffle(filler_chars)

    # 5. Build the final password: [Starting Letter] + [Shuffled Filler]
    password.extend(filler_chars)

    return "".join(password)

def get_or_generate_passwords(user_emails, password_file):
    """
    Checks for the password file. If it exists, loads passwords.
    If not, generates new passwords and saves them to the file.
    """
    passwords = {}

    # 1. Check if the password file exists
    if os.path.exists(password_file):
        try:
            with open(password_file, 'r') as f:
                passwords = json.load(f)

            # Verify all expected users are in the loaded file
            missing_users = [email for email in user_emails if email not in passwords]
            if not missing_users:
                print(f"✅ Passwords loaded successfully from **{password_file}**.")
                return passwords
            else:
                # If file exists but is incomplete, log and proceed to regenerate
                print(f"⚠️ Warning: Password file exists but is missing entries for: {', '.join(missing_users)}. Regenerating all.")
                passwords = {} # Reset to regenerate all

        except json.JSONDecodeError:
            print(f"❌ Error decoding JSON from **{password_file}**. File may be corrupt. Generating new passwords.")
            passwords = {} # Reset to regenerate all

    # 2. Generate passwords if file doesn't exist or is invalid/incomplete
    if not passwords:
        for email in user_emails:
            passwords[email] = generate_strong_password(length=32)

        # Save the newly generated passwords
        try:
            with open(password_file, 'w') as f:
                json.dump(passwords, f, indent=4)
            print(f"🎉 Passwords generated and saved to **{password_file}**.")
        except IOError as e:
            print(f"❌ Error writing password file **{password_file}**: {e}")
            sys.exit(1)

    return passwords

# --- User Credentials (Conditional Password Assignment) ---

USER_EMAIL_1="SaulGoodman@hhm.com"
USER_EMAIL_2="Chuck@hhm.com"

# Define the list of users we need passwords for
user_emails = [USER_EMAIL_1, USER_EMAIL_2]

# Get or generate the passwords
user_passwords = get_or_generate_passwords(user_emails, PASSWORD_FILE)

# Assign the passwords to the final variables
USER_PWD_1 = user_passwords[USER_EMAIL_1]
USER_PWD_2 = user_passwords[USER_EMAIL_2]


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
    response = None

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

    except client.exceptions.UsernameExistsException:
        print(f"❌ User {username} already exists.")
    except Exception as e:
        print(f"❌ Error creating user: {e}")
    return response

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

# --- Simulation ---

print('-- CREATING USERS --')
if create_user_without_force_change(USER_EMAIL_1, USER_EMAIL_1, USER_PWD_1) is not None and create_user_without_force_change(USER_EMAIL_2, USER_EMAIL_2, USER_PWD_2) is not None:
  identity1_id = test_the_thing(USER_EMAIL_1,USER_PWD_1)
  identity2_id = test_the_thing(USER_EMAIL_2,USER_PWD_2)
  identity2_id = test_the_thing(USER_EMAIL_2,USER_PWD_2,use_identity=identity1_id)
else:
  print("❌ FAILURE: Can not create users")
