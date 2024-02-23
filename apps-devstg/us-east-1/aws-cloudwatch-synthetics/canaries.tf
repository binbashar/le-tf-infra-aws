module "target-canary" {
  source = "github.com/binbashar/terraform-aws-cloudwatch-synthetics.git?ref=1.4.0"

  name_prefix = "${var.project}-${var.environment}"
  environment = var.environment

  schedule_expression = "rate(5 minutes)"
  s3_artifact_bucket  = module.target_canary_s3_bucket.s3_bucket_id # must pre-exist
  alarm_email         = null                                        # an email or null value
  endpoints           = { "target-group" = { url = "http://www.binbash.co/" } }
  managedby           = "managedby@binbash.co"
  repository          = "https://github.com/binbashar/terraform-aws-cloudwatch-synthetics"

  create_topic = false
  #existent_topic_arn = "arn:aws:sns:us-east-1:523857393444:sns-topic-slack-notify-monitoring"
  existent_topic_arn = data.terraform_remote_state.notifications.outputs.sns_topic_arn_monitoring

  # what networks it has to work in?
  #subnet_ids                = data.terraform_remote_state.local-vpcs.outputs.private_subnets
  #security_group_ids        = [aws_security_group.target-canary-sg.id]

  tags = local.tags

  depends_on = [module.target_canary_s3_bucket, aws_security_group.target-canary-sg]
}
