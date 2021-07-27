# Terraform & AWS Authentication with MFA support

## Brief
This document explains what is needed to enable MFA support when using Binbash Leverage's Terraform workflow.

## Context
Leverage relies on a CLI helper, Docker images and other conventions to create an AWS multi-account approach via Terraform. Enforcing MFA on AWS API calls is achieved through AWS IAM policies which works well with the AWS Console and the AWS CLI. Whenever you switch to a role that enforces MFA, the AWS Console or the AWS CLI will prompt the user to input the Time-based One Time Password (TOTP).
However, when we tried to use the same approach on Leverage, we found that the same could not be achieved as Terraform does not prompt the user for the TOTP. Moreover, since Leverage approach relies on multiple AWS profiles (defined in AWS credentials files), it becomes even more complicated to enable MFA without changing Leverage workflow.

## Our Solution
Since we wanted to make as few changes as possible to the Leverage workflow but still be able to enable MFA support we came up with the following solution:
* Create a script that would work as an entrypoint to the Terraform docker image.
* Such script should take care of prompting the user for the TOTP in order to build the temporary AWS credentials that Terraform needs to run the normal workflow.
* After that the script should hand off to another process (typically Terraform).

## Implementation
Currently there are 2 scripts that support MFA functionality. They will be described below:

### MFA Script (aws-mfa-entrypoint.sh)
This is a bash implementations that relies on the AWS CLI for setting up profiles in credentials files. The AWS CLI is also used to assume all given roles.
A major drawback about this script is that it relies on having your AWS programmatic keys as plain text on file. This means that every user will have to take care of securing their workstations in order to avoid having those credentials compromised.

### aws-vault (aws-mfa-entrypoint-awsvault.sh)
This script enhances the script above. It actually reuses some of the logic of such script but it relies on aws-vault to provide MFA support and credentials encryption. That means that your programmatic keys will be stored in an encrypted file that will have to be decrypted every time aws-vault needs to get access to them. And that is actually a caveat of this approach as the passphrase of the encrypted file will have to be input at least once, depending on the number of profiles used by any given Terraform layer.


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
Make sure you set the profile that has MFA enabled in backend.config file so that Terraform uses

### Setting up credentials for using aws-vault alternative
If you choose to go with the script that uses aws-vault you need to set up your AWS credentials first:
- Install aws-vault
- Run `aws-vault add [profile-name] --backend=file` to create a profile which credentials will be stored encrypted. For instance, if you set up a profile that uses a role that needs to be assumed through a source_profile named `bb-security`, then you would use `aws-vault add bb-security --backend=file`
- Next you should be prompted to type in your programmatic credentials
- Also, you must set up a passphrase which will be used to retrieve your credentials later on
- Repeat these steps for as many profiles that you need to create


## Shortcomings

### MFA cannot be enabled partially on an account
Once you enable MFA on a layer in a any of the account directories you need to enable it on all the layers. That is because all layers share the same backend.config file which points to an AWS profile. Such profile is linked to a role and, if the role enforces MFA support, you can work around that.


## Troubleshooting

### aws-vault does not show any profiles under the Profile column
- Make sure you set the environment variables (AWS_CONFIG_FILE and AWS_SHARED_CREDENTIALS_FILE) that point to where the AWS config/credentials files can be found. aws-vault honors those env vars just as well as the AWS CLI.

### aws-vault does not show the credentials I just set up under the Credentials column
- Make sure you passing `--backend=file`
- Also confirm that there is a directory named `.awsvault` in your home directory. This directory should include a `keys` subdirectory with a file that follow after the profiles you created.

