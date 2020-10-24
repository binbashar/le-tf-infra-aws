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

### Consideration 

In order to get the necessary `secrets.dec.tf` file referenced at `plaintext = local.secrets.slack_webhook_monitoring`
please execute `make decrypt` in this same path

```
╭─delivery at delivery-ops in ~/Binbash/repos/Flex/devops-tf-infra/shared/notifications on master✔ 20-10-21 - 9:27:51
╰─⠠⠵ make decrypt 
ansible-vault decrypt --output secrets.dec.tf secrets.enc
Vault password: 
Decryption successful
```


