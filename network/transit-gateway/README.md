# Transit Gateway (tgw)

## Requisites
Make sure you have enabled RAM in the Organization account by:

* Setting RAM to Access enabled in AWS Oganizations > Services
* **Enable sharing with AWS Organizations**  in Resource Acccess Manager > Settings


## Deployment

In order to deploy the Transit Gateway follow these steps:

1. First time deployment: Set to `false` all vpc attachments first in `var.enable_vpc_attach`
2. After deploying the Transit Gateway select the vpc attachment to enable in the `var.enable_vpc_attach` by setting to `true`
