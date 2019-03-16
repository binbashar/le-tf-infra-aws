# -*- coding: utf-8 -*-
import logging

class OrganizationalUnit(object):
    def __init__(self, org_client, debug = False):
        self.org_client = org_client
        self.debug = debug
    
    def create(self, org_unit_spec, org_root):
        create_result = self.org_client.create_organizational_unit(ParentId=org_root['Id'], Name=org_unit_spec['name'])
        if 'OrganizationalUnit' in create_result:
            return create_result['OrganizationalUnit']
        else:
            logging.error("Create Organizational Unit failed with result=%s" % create_result)
        
        return None
    
    def get_all(self, root):
        try:
            org_units = self.org_client.list_organizational_units_for_parent(ParentId=root['Id'])
            if 'OrganizationalUnits' in org_units:
                return org_units['OrganizationalUnits']
        except Exception as e:
            logging.warn("Unable to get organizational units")
        
        return []
