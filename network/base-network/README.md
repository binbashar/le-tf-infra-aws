# Transit Gateway (tgw)

## Requisites
Make sure you have enabled RAM in the Organization account by:

* Setting RAM to Access enabled in *AWS Organization > Services*

* **Enable sharing with AWS Organizations**  in the AWS console go to *Resource Access Manager > Settings* or via AWS CLI:

  `aws ram enable-sharing-with-aws-organization`


## Deployment

In order to deploy the Transit Gateway follow these steps:

1. First time deployment: Set to `false` all vpc attachments first in `var.enable_vpc_attach`
2. After deploying the Transit Gateway select the vpc attachment to enable in the `var.enable_vpc_attach` by setting to `true`



References:

https://docs.aws.amazon.com/ram/latest/userguide/getting-started-sharing.html

https://docs.aws.amazon.com/cli/latest/reference/ram/enable-sharing-with-aws-organization.html
