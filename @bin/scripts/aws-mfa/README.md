# Terraform & AWS Authentication with MFA support

## Brief
This document explains what is needed to enable MFA support when using Binbash Leverage's Terraform workflow.


## Context
Leverage relies on Makefiles, Docker images and other conventions to implement an AWS multi-account approach via Terraform. Enforcing MFA on AWS API calls is achieved through AWS IAM policies which works well with the AWS Console and the AWS CLI. Whenever you switch to a role that enforces MFA, the AWS Console or the AWS CLI will prompt the user to input the Time-based One Time Password (TOTP).
When you try the same approach on Leverage, you find that the same cannot be achieved because Terraform does not prompt for the TOTP. Moreover, since Leverage approach relies on multiple profiles in the AWS credentials files, it becomes even more difficult to enable MFA without changing Leverage workflow.


## Our Solution
Since we wanted to make as few changes as possible the Leverage workflow and still be able to enable MFA support we came up with the following solution:
* Create a script that should work as an entrypoint to the Terraform image
* Such script should take care of prompting the user for the TOTP in order to build the temporary AWS credentials that Terraform needs to run the normal workflow
* After that the script should hand off to another process (typically Terraform)


## Assets
* @bin/scripts/aws-mfa/aws-mfa-entrypoint.sh    => This is the script that builds the AWS credentials
* @bin/makefiles/terraform12/terraform12-mfa.mk => This is the Makefile that supports the MFA workflow


## Pre-requisites

### Enable MFA on roles
This is enabled on a per-role basis. Since we use the `iam-assumable-role` module, which is part of the `terraform-aws-iam` module,  we can enable MFA for any role with the following module parameter: `role_requires_mfa = true`

### Enable MFA on AWS
Follow the official documentation to enable MFA on your AWS account: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_mfa_enable_virtual.html

### Configure AWS credentials
Your AWS config file needs to include 2 extra entries: `mfa_serial` and `totp_key`. For instance:
```
[profile bb-security-admin]
output = json
region = us-east-1
role_arn = arn:aws:iam::{ACCOUNT_ID}:role/Admin
mfa_serial = arn:aws:iam::{ACCOUNT_ID}:mfa/john.doe
totp_key = {YOUR_TOTP_KEY}
source_profile = bb-security
```
In the example above you can see the aforementioned entries. The `mfa_serial` entry and the `totp_key` entry can be obtained when you create an MFA device. The `totp_key` is optional, if you don't provide one, the AWS MFA script will prompt you to input the TOTP in order to generate the temporary credentials that Terraform needs.

### Set the appropriate profile in the backend.config file
Make sure you set the profile that has MFA enabled so that


## Shortcomings

### Temporary credentials reuse is not supported
The MFA workflow will generate new credentials every time you run a Makefile target that calls the AWS MFA script. Credentials are not checked for validity in order to favor reuse and speed up the temporary credentials generation procedure.

One not-to-so-hard option for implementing credentials caching is to save the temporary credentials in the path where the actual AWS credentials are mounted but using a different name for each file. Such name should contain the profile that was used to generate the credentials. The MFA script should be modified to do that.
Then the script should also implement a small validation code that takes into account the creation date of those files in order to determine if such cached files are still valid or not, depending on the session duration time and the difference between the files creation date and the current date.

### MFA cannot be enabled partially on an account
Once you enable MFA on a layer in a any of the account directories you need to enable it on all the layers. That is because all layers share the same backend.config file which points to an AWS profile. Such profile is linked to a role and, if the role enforces MFA support, you can work around that.
