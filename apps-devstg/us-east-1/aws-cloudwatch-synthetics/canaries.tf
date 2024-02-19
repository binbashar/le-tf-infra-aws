module "target-canary" {
  source              = "git::https://github.com/binbashar/terraform-aws-cloudwatch-synthetics.git?ref=FEATURE/improving-module"
  #version             = "1.3.1"

  name_prefix         = "${var.project}-${var.environment}"
  environment         = var.environment

  schedule_expression = "rate(5 minutes)"
  s3_artifact_bucket  = module.target_canary_s3_bucket.s3_bucket_id              # must pre-exist
  alarm_email         = null # an email or null value
  endpoints           = { "target-group" = { url = "http://costenginetool.basemates.co/" } }
  managedby           = "managedby@binbash.co"
  repository          = "https://github.com/binbashar/terraform-aws-cloudwatch-synthetics"

  # what networks it has to work in?
  #subnet_ids                = data.terraform_remote_state.local-vpcs.outputs.private_subnets
  #security_group_ids        = [resource.aws_security_group.target-canary-sg.id]

  tags                = local.tags

  depends_on = [module.target_canary_s3_bucket]
}
