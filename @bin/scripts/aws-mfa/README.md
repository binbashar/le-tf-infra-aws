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

### Multiple profiles in the same Terraform layer are not supported
The solution does not support all the use cases that Leverage has implemented.

The MFA script only generates temporary credentials for the main profile:

```provider "aws" {
  ...
  profile = var.profile
  ...
}
```

Other profiles are not supported. Typically data blocks that point to a different account. For instance:

```
data "terraform_remote_state" "vpc-apps-dev" {
  backend = "s3"

  config = {
    region  = var.region
    profile = "${var.project}-apps-devstg-devops"
    bucket  = "${var.project}-apps-devstg-terraform-backend"
    key     = "apps-devstg/network/terraform.tfstate"
  }
}
```

Such data blocks refer to a different profile and need a different set of credentials. In order to support them, the script would also need to discover those profiles and prompt the user for the corresponding TOTP for that profile.

### Temporary credentials reuse is not supported
The MFA workflow will generate new credentials every time you run a Makefile target that calls the AWS MFA script. Credentials are not checked for validity in order to favor reuse and speed up the temporary credentials generation procedure.
