# AWS Organizations

## Overview
The files in this folder should reflect the current structure of the AWS Organization implementation defined for the current project. These files should also be used to apply further updates to such structure.

## Note about the chosen tools
At the time of this implementation the only tools that provided the kind of support we needed were:
1. AWS CLI (better for automation)
2. AWS Web Console (much harder to automate)

What was the status of other tools we also use? Here:
1. Terraform (only partial support; e.g. no OUs)
2. CloudFormation (no support)
3. Ansible (no support)


## Instructions
- Use `config.yaml` to define organizations, organizational units, accounts and policies
- Run `python main.py -r [AWS_REGION] -p [AWS_PROFILE]`

## Important considerations
- The script is meant to automate the initial setup of the organization
- Deleting or updating resources is not supported yet
- Only new organizational units, accounts, and policies will be created
- Invited accounts are not fully supported either due to the asynchronous nature of their creation

## Ref
- http://2ndwatch.com/blog/automated-aws-organizations-linked-account-creation-deep-dive/
- https://theithollow.com/2018/02/05/add-new-aws-account-existing-organization-cli/