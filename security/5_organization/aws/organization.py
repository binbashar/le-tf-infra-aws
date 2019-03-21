# -*- coding: utf-8 -*-
import logging

class Organization(object):
    def __init__(self, org_client, debug = False):
        self.org_client = org_client
        self.debug = debug
    
    def describe(self):
        try:
            org_data = self.org_client.describe_organization()
            if 'Organization' in org_data:
                return org_data['Organization']
        except Exception as e:
            logging.warn("This account is not a member of an organization")
        
        return None
    
    def create(self, org_spec):
        create_result = self.org_client.create_organization(FeatureSet=org_spec['feature_set'])
        if 'Organization' in create_result and 'Id' in create_result['Organization']:
            return create_result['Organization']
        else:
            raise Exception('Unable to get or create the organization')
        
        return None
    
    def get_organization_root(self):
        try:
            roots_response = self.org_client.list_roots()
            if 'Roots' in roots_response:
                for root in roots_response['Roots']:
                    if root['Name'] == 'Root':
                        return root
        except Exception as e:
            logging.warn("This account is not a member of an organization")
        
        return None
