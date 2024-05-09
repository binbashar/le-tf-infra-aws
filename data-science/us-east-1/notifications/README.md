# Slack notification with KMS encrypted webhook URL

Configuration in this directory creates an SNS topic that sends messages to a Slack channel with Slack webhook URL encrypted using KMS.

## KMS keys

There are 3 ways to define KMS key which should be used by Lambda function:

1. Create [aws_kms_key resource](https://www.terraform.io/docs/providers/aws/r/kms_key.html) and put ARN of it as `kms_key_arn` argument to this module
2. Use [aws_kms_alias data-source](https://www.terraform.io/docs/providers/aws/d/kms_alias.html) to get an existing KMS key alias and put ARN of it as `kms_key_arn` argument to this module

Note: Set `create_with_kms_key = true` when providing value of `kms_key_arn` to create required IAM policy which allows to decrypt using specified KMS key.

### Option 1:
```
resource "aws_kms_key" "this" {
  description = "KMS key for notify-slack test"
}

resource "aws_kms_alias" "this" {
  name          = "alias/kms-test-key"
  target_key_id = "${aws_kms_key.this.id}"
}

kms_key_arn = "${aws_kms_key.this.arn}"
create_with_kms_key = true
```
