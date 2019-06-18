config {
  terraform_version = "0.11.13"
  deep_check = true

  // If you have shared credentials, you can specify credentials profile name. However TFLint supports
  // only ~/.aws/credentials as shared credentials location.
  aws_credentials = {
    profile = "AWS_PROFILE"
    region = "us-east-1"
  }

  ignore_module = {
    "github.com/wata727/example-module" = true
  }

  varfile = [
    "variables.tf"]
}

//
//Rules
//
//You can make settings for each rule in the rule block. Currently, it can set only enabled option.
// If you set enabled = false, TFLint doesn't check templates by this rule.
//
// Consider review https://github.com/wata727/tflint/tree/master/docs in order to disable certain rules if needed
//
// Eg:
//rule "aws_instance_invalid_type" {
//  enabled = false
//}
//
//rule "aws_instance_previous_type" {
//  enabled = false
//}
