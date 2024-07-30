#
# Enable encrypted EBS by default (HIPAA)
#
resource "aws_ebs_encryption_by_default" "main" {
  enabled = true
}

#
# Disable public access through ACLs or bucket policies to all buckets by default
#
resource "aws_s3_account_public_access_block" "main" {
  block_public_acls   = true
  block_public_policy = true
}

module "root-login-notifications" {
  source = "github.com/binbashar/terraform-aws-root-login-notifications.git?ref=v2.3.0"

  alarm_suffix   = "${var.environment}-account"
  send_sns       = true
  sns_topic_name = var.sns_topic_name_monitoring_sec
}
