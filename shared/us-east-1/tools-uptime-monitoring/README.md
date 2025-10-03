# AWS Cloudwatch Synthetics

## Overview

This module creates `canaries` to check endpoints.

`canaries` is how AWS Cloudwatch Synthetics calls the Lambdas that will check endpoints.

More documentation [here](https://docs.aws.amazon.com/AmazonSynthetics/latest/APIReference/Welcome.html).

## Dependencies

This module uses a fork of [this module](https://github.com/clouddrove/terraform-aws-cloudwatch-synthetics) hosted in `binbashar` space to add a few modifications.

## Notifications

Same as with the original module, `alarm_email` can be set when calling the module to set the email that will suscribe to the SNS topic.

As per the `binbash Leverage` needs, this email can be set to null, so later the [notifications](https://github.com/binbashar/le-tf-infra-aws/tree/master/apps-devstg/us-east-1/notifications) module can be used to suscribe to this topic. For this an output is added with the topic name.

### Setting `notifications` layer

#### To use the topic created in the `synthetics` layer

In the `notifications` layer add the remote state for the `synthetics` layer.

``` hcl
data "terraform_remote_state" "aws-cloudwatch-synthetics" {
  backend = "s3"

  config = {
    region  = var.region
    profile = var.profile
    bucket  = var.bucket
    key     = "${var.environment}/aws-cloudwatch-synthetics/terraform.tfstate"
  }
}
```

Extract the topic name:

``` hcl
  arn_array = split(":", data.terraform_remote_state.aws-cloudwatch-synthetics.outputs.topic_target_canary)
  topic_name = local.arn_array[length(local.arn_array) - 1]
```

Set the topic to not be created:

``` hcl
  create_sns_topic = false
```

And set the topic name from the `synthetics` layer:

``` hcl
  sns_topic_name       = local.topic_name
```

#### To use the topic created in the `notifications` layer

In the `synthetics` layer add the remote state for the `notifications` layer.

``` hcl
data "terraform_remote_state" "notifications" {
  backend = "s3"

  config = {
    region  = var.region
    profile = var.profile
    bucket  = var.bucket
    key     = "${var.environment}/notifications/terraform.tfstate"
  }
}
```

In `canaries.tf` file add (or set to `false`) this line:

``` hcl
  create_topic       = false
```

And set the topic name from the remote state:

``` hcl
  existent_topic_arn = data.terraform_remote_state.notifications.outputs.sns_topic_arn_monitoring
```



## IAM permission

Note if you are using the default `binbash Leverage` configuration, and you are using *DevOps* profile with SSO, maybe you'll have to add this permission to your *DevOps* policy:

``` hcl
synthetics:*
```

*(or something more specific if you want to narrow the permission set)*

## Known issues

If a canary in a private subnet is created, and then it is moved out from that subnet, e.g. you created the private canary, then comment out these lines:

``` hcl
  #subnet_ids                = data.terraform_remote_state.local-vpcs.outputs.private_subnets
  #security_group_ids        = [aws_security_group.target-canary-sg.id]
```

...and re apply.

In this case there is a chance the ENIs the canary took in first place in the private subnet remain attached even if they are not being used.

E.g., if you want to destroy this infra the ENIs can not be detached even if the Lambda does not exist anymore.

In this case, wait for 24hs, AWS should recognize the unused ENIs and will detach them automagically.
