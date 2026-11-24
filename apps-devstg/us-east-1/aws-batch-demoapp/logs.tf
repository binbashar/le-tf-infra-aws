#=============================================#
# CloudWatch Logs for the jobs                #
#=============================================#
# Every job definition sends its output here (awslogs driver), one stream prefix per job definition.
resource "aws_cloudwatch_log_group" "jobs" {
  name              = local.log_group_name
  retention_in_days = var.log_retention_days
  kms_key_id        = var.log_group_kms_encryption ? data.terraform_remote_state.keys.outputs.aws_kms_key_arn : null

  tags = local.tags
}
