import logging
from datetime import datetime
import workflow
import spec
import optparse


### Entry point
def main_handler():
    logging.info("START Organizations script at %s" % datetime.today().strftime('%Y-%m-%d'))
    
    # Configure and check CLI arguments
    parser = optparse.OptionParser()
    parser.add_option('-r', '--region', dest="region", help="AWS Region")
    parser.add_option('-p', '--profile', dest="profile", help="AWS Profile")
    options, args = parser.parse_args()
    if not options.region or not options.profile:
        logging.error("Missing mandatory arguments: region and profile")
        return -1
    
    # Build workflow helper
    org_workflow = workflow.Workflow(aws_region=options.region, aws_profile=options.profile, debug=False)
    
    # Load spec file
    spec_data = spec.load('config.yaml')
    
    # Get organization or create it if non-existing
    organization = org_workflow.create_organization(spec_data['organization'])
    
    # Create policies if necessary
    policies = org_workflow.create_policies(spec_data['policies'])
    
    # Go through each organizational units
    for org_unit_spec in spec_data['organizational_units']:
        
        # Create organizational unit if it doesn't already exist
        org_unit = org_workflow.get_or_create_organizational_unit(org_unit_spec)
        
        # Attach policy to organizational unit
        policy_spec = spec.find_policy_by_name(org_unit_spec['policy'], spec_data['policies'])
        org_workflow.attach_policy(org_unit['Id'], policy_spec, policies)
        
        # Go through each account
        for account_spec in org_unit_spec['accounts']:
            
            if account_spec['type'] == 'new':
                # Create account if it doesn't already exist
                account = org_workflow.get_or_create_account(account_spec)
                
                # Move account to its OU if it's not already part of it
                org_workflow.move_account(account, org_unit)
                
            elif account_spec['type'] == 'invite':
                # Invite account to the organization
                org_workflow.invite_account(account_spec)
    
    logging.info("FINISH Organizations script at %s" % datetime.today().strftime('%Y-%m-%d'))
    return 0


### Initialization
def init_handler():
    # Logging configuration
    logging.basicConfig(format='[%(levelname)s] %(message)s', level=logging.INFO)


if __name__ == "__main__":
    init_handler()
    main_handler()