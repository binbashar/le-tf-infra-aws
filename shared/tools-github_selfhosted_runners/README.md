# Self-hosted Github Actions Runners

## Instructions

### Overview
* Github App - Part 1
* Set up Terraform
  * Enable NAT Gateway
  * Create Github Actions Runners
* Github App - Part 2

### Github App - Part 1
In a nutshell you need to create a Github App, with the right permissions, and get the app id, client id, client secret and app key. Please follow the instructions here:
https://github.com/philips-labs/terraform-aws-github-runner#setup-github-app-part-1

### Set up Terraform
1. The runners will need access to the Internet for downloading tools and most likely the workflows you run will need to download stuff too. If the runners are created in private subnets, they will need to enable the NAT gateway first.

2. One of the first steps is to download the code that the module needs to create the Lambda functions. You can do that by using these steps:
```
cd lambdas-download/
terraform init
terraform apply
```
NOTE: you can also achieve that through Leverage CLI by first running `leverage shell` and then following the commands listed above.

That small layer purpose simply provides a way to download the zip files that contain the code that will be uploaded to AWS Lambda.

3. After that you should be able to apply the main layer that holds the self-hosted runners.

4. Full instructions can be found here: https://github.com/philips-labs/terraform-aws-github-runner#setup-terraform-module

### Github App - Part 2
After you created the AWS resources, you should have a Webhook endpoint in the output. You have to use it to activate the webhook in the Github App. Detailed instructions here:
https://github.com/philips-labs/terraform-aws-github-runner#setup-github-app-part-2

### Last minute checks
- Please remember that the Github App needs to be installed in your organization.
- Also, do not forget to create an offline runner. Refer to this to review why: https://help.github.com/en/actions/hosting-your-own-runners/about-self-hosted-runners
- Remember that the self-hosted runners need internet connectivity to provision software and also to talk back to Github to ship execution logs. We run our self-hosted runners in private subnets under Shared account, so it is mandatory to enable the NAT Gateway in said account for those runners to be able to pick up workflows which have matching labels.

## Troubleshooting
* Refer to this: https://github.com/philips-labs/terraform-aws-github-runner#debugging
* Did you install the Github App?
* Did you create an offline runner?
* Does any of the labels of your offline runner match those of your workflows?
* Do your self-hosted runners need and have access to the Internet?
* Do your self-hosted runners have the files/binaries your workflows need?
* Do your self-hosted runners have the AWS permissions (EC2 instance profile) your workflows need?
