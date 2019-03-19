# -*- coding: utf-8 -*-
import logging

class Account(object):
    STATUS_SUCCEEDED = 'SUCCEEDED'
    STATUS_FAILED = 'FAILED'
    STATUS_INPROGRESS = 'IN_PROGRESS'
    
    INVITE_NOTES = 'Automated Invite from AWS Organization'
    
    def __init__(self, org_client, debug = False):
        self.org_client = org_client
        self.debug = debug
    
    def describe(self, account_id):
        account = self.org_client.describe_account(AccountId=account_id)
        if 'Account' in account:
            return account['Account']
        
        return None
    
    def create(self, account_spec):
        create_result = self.org_client.create_account(
            Email=account_spec['email'],
            AccountName=account_spec['name'],
            IamUserAccessToBilling='ALLOW'
        )
        if 'CreateAccountStatus' in create_result:
            return create_result['CreateAccountStatus']
        
        return None
    
    def get_creation_status(self, request_id):
        create_account_status = self.org_client.describe_create_account_status(CreateAccountRequestId=request_id)
        if 'CreateAccountStatus' in create_account_status and 'Id' in create_account_status['CreateAccountStatus']:
            return create_account_status['CreateAccountStatus']
        
        return None
    
    def get_all(self):
        try:
            accounts = self.org_client.list_accounts()
            if 'Accounts' in accounts:
                return accounts['Accounts']
        except Exception as e:
            logging.error("Unable to list accounts")
        
        return []
    
    def list_by_parent(self, parent_id):
        list_result = self.org_client.list_accounts_for_parent(ParentId=parent_id)
        if 'Accounts' in list_result:
            return list_result['Accounts']
        
        return []
    
    def move(self, account_id, root_id, unit_id):
        try:
            self.org_client.move_account(
                AccountId=account_id,
                SourceParentId=root_id,
                DestinationParentId=unit_id
            )
        except Exception as e:
            logging.error("Unable to move account with id=%s from source=%s to dest=%s" % (account_id, root_id, unit_id))
    
    def invite(self, account_spec):
        try:
            response = self.org_client.invite_account_to_organization(
                Target={
                    'Id': account_spec['email'],
                    'Type': 'EMAIL'
                },
                Notes=self.INVITE_NOTES
            )
            if 'Handshake' in response:
                return response['Handshake']
        
        except Exception as e:
            logging.error("Unable to invite account with data=%s" % account_spec)
        
        return None
