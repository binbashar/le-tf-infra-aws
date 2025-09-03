#
# Enable encrypted EBS by default (HIPAA)
#
resource "aws_ebs_encryption_by_default" "main" {
  for_each = local.account_settings
  provider = aws.accounts[each.key]
  enabled = each.value.inputs.ebs_encryption
}

#
# Disable public access through ACLs or bucket policies to all buckets by default
#
resource "aws_s3_account_public_access_block" "main" {
  for_each = local.account_settings
  provider = aws.accounts[each.key]
  block_public_acls   = each.value.inputs.block_public_acls
  block_public_policy = each.value.inputs.block_public_policy
}

//module "root-login-notifications" {
//  for_each = local.accounts_settings
//  source = "github.com/binbashar/terraform-aws-root-login-notifications.git?ref=v2.3.0"
//  providers = {
//    aws = aws.by_region[each.key]
//  }
//  alarm_suffix   = "${each.value.environment}-account"
//  send_sns       = each.value.parameters.send_sns
//  sns_topic_name = each.value.parameters.sns_topic_name_monitoring_security
//}
