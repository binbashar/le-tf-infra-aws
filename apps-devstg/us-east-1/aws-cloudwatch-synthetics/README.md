# AWS Cloudwatch Synthetics

## Overview

This module creates `canaries` to check endpoints.

`canaries` is how AWS Cloudwatch Synthetics calls the Lambdas that will check endpoints.

More documentation [here](https://docs.aws.amazon.com/AmazonSynthetics/latest/APIReference/Welcome.html).

## Dependencies

This module uses a fork of [this module](https://github.com/clouddrove/terraform-aws-cloudwatch-synthetics) hosted on `binbashar` space to add a few modifications.

## Notifications

Same as with the original module, `alarm_email` can be set when calling the module to set the email that will suscribe to the SNS topic.

As per the `binbash Leverage` needs, this email can be set to null, so later the [notifications](https://github.com/binbashar/le-tf-infra-aws/tree/master/apps-devstg/us-east-1/notifications) module can be used to suscribe to this topic. For this an output is added with the topic name.

### Setting `notifications` layer

Add the remote state for the `synthetics` layer.

``` json
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

``` json
  arn_array = split(":", data.terraform_remote_state.aws-cloudwatch-synthetics.outputs.topic_target_canary)
  topic_name = local.arn_array[length(local.arn_array) - 1]
```

Set the topic to not be created:

``` json
  create_sns_topic = false
```

And set the topic name from the `synthetics` layer:

``` json
  sns_topic_name       = local.topic_name
```

## IAM permission

Note if you are using the default `binbash Leverage` configuration, and you are using *DevOps* profile with SSO, maybe you'll have to add this permission to your *DevOps* policy:

``` json
synthetics:*
```

*(or something more specific if you want to narrow the permission set)*

