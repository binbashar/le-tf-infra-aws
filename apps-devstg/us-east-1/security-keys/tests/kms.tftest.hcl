#mock_provider "aws" {}

#override_data  {
#    target = data.aws_iam_policy_document.kms
#    values = {
#      json = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Sid\":\"Enable IAM User Permissions\",\"Effect\":\"Allow\",\"Action\":[\"kms:*\"],\"Resource\":\"*\",\"Principal\":{\"AWS\":[\"arn:aws:iam::123456789012:root\",\"arn:aws:iam::123456789012:user/s3_demo\"]}},{\"Sid\":\"Enable S3 Service\",\"Effect\":\"Allow\",\"Action\":[\"kms:Encrypt*\",\"kms:Decrypt*\",\"kms:ReEncrypt*\",\"kms:GenerateDataKey*\",\"kms:Describe*\"],\"Resource\":\"*\",\"Principal\":{\"Service\":\"s3.us-west-2.amazonaws.com\"}},{\"Sid\":\"Enable CloudWatch Logs Service\",\"Effect\":\"Allow\",\"Action\":[\"kms:Encrypt*\",\"kms:Decrypt*\",\"kms:ReEncrypt*\",\"kms:GenerateDataKey*\",\"kms:Describe*\"],\"Resource\":\"*\",\"Principal\":{\"Service\":\"logs.us-west-2.amazonaws.com\"}}]}" 
#    }
# }

variables {
  kms_key_name        = "test-kms"
  environment         = "test"
  enable_remote_state = true
}

run "valid_key_alias_name" {
  assert {
    condition     = module.kms_key.alias_name == "alias/bb_test_test-kms_key"
    error_message = "The KMS key alias name is not correct"
  }
}
