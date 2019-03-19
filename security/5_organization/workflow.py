import boto3
import logging
import aws.organization
import aws.organizational_unit
import aws.account
import aws.policy
from time import sleep

class Workflow(object):
    def __init__(self, aws_region, aws_profile, debug = False):
        self.aws_org_client = self._get_aws_client(aws_region, aws_profile)
        self.cached_org_units = None
        self.cached_org_root = None
        self.cached_accounts = None
        self.debug = debug
    
    #
    # Check if the organization was already created. Otherwise, create it.
    # 
    def create_organization(self, org_spec):
        organization = aws.organization.Organization(self.aws_org_client, self.debug)
        org_info = organization.describe()
        if org_info is not None:
            logging.info("Skipping... Organization already exists with id=%s" % org_info['Id'])
            return org_info
        
        created_org = organization.create(org_spec)
        logging.info("OK: Organization was created with id=%s" % created_org['Id'])
        return created_org
    
    #
    # Get all existing policies. Create them if necessary.
    #
    def create_policies(self, policies_spec):
        policy_client = aws.policy.Policy(self.aws_org_client, self.debug)
        existing_policies = policy_client.get_all()
        policies = []
        for policy_spec in policies_spec:
            # Skip AWS managed policies
            if not policy_spec['managed']:
                continue
            
            matching_policy = self.find_matching_policy(policy_spec, existing_policies)
            # If police could not be found in existing policies, create it
            if matching_policy is None:
                new_policy = policy_client.create(policy_spec)
                logging.info("OK... Policy was created with id=%s" % new_policy['Id'])
                policies.append(new_policy)
            else:
                logging.info("Skipping... Policy already exists with name=%s" % policy_spec['name'])
                policies.append(matching_policy)
        
        # Enable policy type if not already enabled
        org_root = self.get_organization_root()
        if not policy_client.is_enabled(org_root):
            enable_policy_result = policy_client.enable(org_root)
            logging.info("- Policy type finished with result=%s" % enable_policy_result)
        
        return policies
    
    def find_matching_policy(self, policy_spec, existing_policies):
        for policy in existing_policies:
            if 'Name' in policy and policy['Name'] == policy_spec['name']:
                return policy
            elif 'name' in policy and policy['name'] == policy_spec['name']:
                return policy
        
        return None
    
    def get_organizational_units(self, root):
        if self.cached_org_units is None:
            org_unit = aws.organizational_unit.OrganizationalUnit(self.aws_org_client, self.debug)
            self.cached_org_units = org_unit.get_all(root)
        
        return self.cached_org_units
    
    def get_organization_root(self):
        if self.cached_org_root is None:
            organization = aws.organization.Organization(self.aws_org_client, self.debug)
            self.cached_org_root = organization.get_organization_root()
        
        return self.cached_org_root
    
    def get_accounts(self):
        if self.cached_accounts is None:
            account = aws.account.Account(self.aws_org_client, self.debug)
            self.cached_accounts = account.get_all()
        
        return self.cached_accounts
    
    #
    # Try and find the unit in the existing units. Otherwise, create a new one.
    #
    def get_or_create_organizational_unit(self, org_unit_spec):
        org_root = self.get_organization_root()
        existing_org_units = self.get_organizational_units(org_root)
        for unit in existing_org_units:
            if org_unit_spec['name'] == unit['Name']:
                logging.info("Skipping... OU already exists with id=%s, name=%s" % (unit['Id'], unit['Name']))
                return unit
        
        org_unit = aws.organizational_unit.OrganizationalUnit(self.aws_org_client, self.debug)
        created_org_unit = org_unit.create(org_unit_spec, org_root)
        logging.info("OK: Organizational Unit was created with id=%s, name=%s" % (created_org_unit['Id'], created_org_unit['Name']))
        return created_org_unit
    
    #
    # Attach policy to OU if necessary
    #
    def attach_policy(self, org_unit_id, policy_spec, existing_policies):
        policy = self.find_matching_policy(policy_spec, existing_policies)
        if 'Id' not in policy:
            logging.warn("Attach policy failed because policy id could not be found for policy_spec=%s" % policy_spec)
            return False
        
        policy_client = aws.policy.Policy(self.aws_org_client, self.debug)
        if policy_client.is_attached(policy['Id'], org_unit_id):
            logging.info("Skipping... Policy with policy_id=%s already attached to org_unit_id=%s" % (policy['Id'], org_unit_id))
        else:
            policy_client.attach(policy['Id'], org_unit_id)
            logging.info("OK: Attach policy finished using policy_id=%s, org_unit_id=%s" % (policy['Id'], org_unit_id))
        
        return True
    
    #
    # Try and find the account in the existing accounts. Otherwise, create a new
    # one. Accounts in progress are confirmed by waiting and re-checking.
    #
    def get_or_create_account(self, account_spec):
        # Try finding the account in the existing accounts
        existing_accounts = self.get_accounts()
        for account in existing_accounts:
            if account_spec['email'] == account['Email']:
                logging.info("Skipping... Account already exists with id=%s, email=%s" % (account['Id'], account['Email']))
                return account
        
        # Otherwise, create a new account
        account = aws.account.Account(self.aws_org_client, self.debug)
        account_request = account.create(account_spec)
        logging.info("OK: Account request returned with state=%s" % account_request['State'])
        
        # Check account creation status
        if account_request['State'] == account.STATUS_INPROGRESS:
            # If account creation is in-progress, try waiting & checking in order to get the full account data
            attempt_number = 0
            max_attempts = 3
            seconds_between_attempts = 5
            while (attempt_number < max_attempts):
                logging.info("\t Checking account creation... attempt_number=%s" % attempt_number)
                creation_status = account.get_creation_status(account_request['Id'])
                if creation_status['State'] == account.STATUS_SUCCEEDED:
                    logging.info("OK: Account creation confirmed with state=%s and id=%s" % (creation_status['State'], creation_status['AccountId']))
                    return account.describe(creation_status['AccountId'])
                
                attempt_number += 1
                sleep(seconds_between_attempts)
            
        elif account_request['State'] == account.STATUS_SUCCEEDED:
            logging.info("OK: Account created with id=%s" % account_request['AccountId'])
            return account.describe(account_request['AccountId'])
        else:
            logging.error("FAILED: Unable to create account with data=%s" % account_request)
        
        return account_request
    
    #
    # Move account to the given organizational unit
    #
    def move_account(self, account, org_unit):
        # Check if account already belongs to the OU
        account_client = aws.account.Account(self.aws_org_client, self.debug)
        existing_accounts = account_client.list_by_parent(org_unit['Id'])
        for existing_account in existing_accounts:
            if existing_account['Id'] == account['Id']:
                logging.info("Skipping... Account is already under org_unit_name=%s" % org_unit['Name'])
                return False
        
        # Otherwise, move account under given organizational unit
        org_root = self.get_organization_root()
        account_client.move(account['Id'], org_root['Id'], org_unit['Id'])
        logging.info("OK: Moved account with id=%s from source_id=%s to dest_id=%s" % (account['Id'], org_root['Id'], org_unit['Id']))
        return True
    
    #
    # Invite an account to organization if necessary
    #
    def invite_account(self, account_spec):
        existing_accounts = self.get_accounts()
        for account in existing_accounts:
            if account_spec['email'] == account['Email']:
                logging.info("Skipping... Account already exists with id=%s, email=%s" % (account['Id'], account['Email']))
                return account
        
        account_client = aws.account.Account(self.aws_org_client, self.debug)
        invite_result = account_client.invite(account_spec)
        logging.info("OK: Invite account finished with result=%s" % invite_result)
    
    #
    # Build AWS client to perform Organizations operations
    #
    def _get_aws_client(self, aws_region, aws_profile):
        logging.info("Creating Organizations client with profile=%s, region=%s" % (aws_profile, aws_region))
        session = boto3.Session(profile_name=aws_profile, region_name=aws_region)
        org_client = session.client('organizations')
        return org_client
