module "target-canary" {
  source = "github.com/binbashar/terraform-aws-cloudwatch-synthetics.git?ref=1.6.0"

  name_prefix = "${var.project}-${var.environment}"
  environment = var.environment

  # How often should the uptime check run?
  schedule_expression = "rate(10 minutes)"
  # The bucket where artifacts (e.g. screenshots) will be stored
  s3_artifact_bucket = module.target_canary_s3_bucket.s3_bucket_id
  alarm_email        = null
  # A list of endpoints to monitor for uptime
  endpoints = {
    "pritunl-g"       = { url = "https://vpn.aws.binbash.com.ar/login" }
  }
  # The following are used for tagging
  managedby       = "managedby@binbash.co"
  repository      = "https://github.com/binbashar/terraform-aws-cloudwatch-synthetics"
  runtime_version = "syn-nodejs-puppeteer-9.1"

  # Whether to create a SNS topic or to reuse an existing one
  create_topic       = false
  existent_topic_arn = data.terraform_remote_state.notifications.outputs.sns_topic_arn_monitoring

  # If the uptime check requires private connectivity, then a list of subnets must be provided
  subnet_ids = [data.terraform_remote_state.local-vpcs.outputs.private_subnets[0]]
  # A security group for controlling the traffic of the Lambda function that runs the checks
  security_group_ids = [aws_security_group.target-canary-sg.id]

  tags = local.tags

}

#
# Security group for granting access from the canary to the targets
#
resource "aws_security_group" "target-canary-sg" {
  name        = "${var.project}-${var.environment}-target-canary-sg"
  description = "Allow TLS outbound traffic"
  vpc_id      = data.terraform_remote_state.local-vpcs.outputs.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["172.18.0.0/20"]
  }
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow internet egress for S3 uploads."
  }

  tags = local.tags
}
