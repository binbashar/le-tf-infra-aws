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
  source          = "git::git@github.com:binbashar/terraform-aws-root-login-notifications.git?ref=v2.1.1"

  alarm_suffix    = var.appsdevstg_account_id
  send_sns        = true
  sns_topic_name  = data.terraform_remote_state.notifications.outputs.sns_topic_name_bb_monitoring_sec
}
