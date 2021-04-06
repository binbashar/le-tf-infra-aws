# Github Self-hosted Runners

## Instructions

### Github App - Part 1
In a nutshell you need to create a Github App, with the right permissions, and get the app id, client id, client secret and app key. Follow the instructions here:
https://github.com/philips-labs/terraform-aws-github-runner#setup-github-app-part-1

### Set up Terraform
https://github.com/philips-labs/terraform-aws-github-runner#setup-terraform-module

One of the first steps is to download the code that the module needs to create the Lambda functions. You can do that by using these steps:
```
cd lambdas-download/
terraform init
terraform apply
```
NOTE: you can also achieve that through Leverage CLI by first running `leverage shell` and then following the commands listed above.

You may already have the service-linked role the documentation mentions; if you don't, you will have to create it as the documentation suggests.

After that you should be able to apply the main layer that holds the self-hosted runners.

### Github App - Part 2
After you created the AWS resources, you should have a Webhook endpoint you can use to set up the webhook in the Github App. Use the following instructions for that:
https://github.com/philips-labs/terraform-aws-github-runner#setup-github-app-part-2


## Troubleshooting
Refer to this: https://github.com/philips-labs/terraform-aws-github-runner#debugging
