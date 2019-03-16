# -*- coding: utf-8 -*-
import logging
import json

class Policy(object):
    iam_version = '2012-10-17'
    type_scp = 'SERVICE_CONTROL_POLICY'
    type_status_enabled = 'ENABLED'
    type_status_disabled = 'DISABLED'
    
    def __init__(self, org_client, debug = False):
        self.org_client = org_client
        self.debug = debug
    
    def get_all(self):
        policies_response = self.org_client.list_policies(Filter='SERVICE_CONTROL_POLICY')
        if 'Policies' in policies_response:
            return policies_response['Policies']
        return []
    
    def create(self, policy_spec):
        policy_statement = dict(
            Effect=policy_spec['policy']['Effect'],
            Action=policy_spec['policy']['Action'],
            Resource=policy_spec['policy']['Resource']
        )
        policy_document = json.dumps(dict(Version=self.iam_version, Statement=[policy_statement]))
        create_result = self.org_client.create_policy(
            Content=policy_document,
            Description=policy_spec['description'],
            Name=policy_spec['name'],
            Type=self.type_scp
        )
        
        if 'Policy' in create_result and 'PolicySummary' in create_result['Policy']:
            return create_result['Policy']['PolicySummary']
        else:
            logging.error("Create Policy failed with result=%s" % create_result)
        
        return None
    
    def is_enabled(self, org_root):
        if 'PolicyTypes' in org_root:
            for policy_type in org_root['PolicyTypes']:
                if policy_type['Type'] == self.type_scp and policy_type['Status'] == 'ENABLED':
                    return True
        
        return False
    
    def enable(self, org_root):
        enable_result = self.org_client.enable_policy_type(RootId=org_root['Id'], PolicyType=self.type_scp)
        if 'Root' in enable_result:
            return enable_result['Root']
        else:
            logging.error("Enable Policy failed with exception=%s" % enable_result)
        
        return None
    
    def is_attached(self, policy_id, target_id):
        policies_list = self.org_client.list_policies_for_target(
            TargetId=target_id,
            Filter=self.type_scp
        )
        if 'Policies' in policies_list:
            for policy in policies_list['Policies']:
                if policy['Id'] == policy_id:
                    return True
        
        return False
    
    def attach(self, policy_id, target_id):
        try:
            self.aws_org_client.attach_policy(
                PolicyId=policy_id,
                TargetId=target_id
            )
        except Exception as e:
            logging.error("Unable to attach policy policy_id=%s to target_id=%s" % (policy_id, target_id))
