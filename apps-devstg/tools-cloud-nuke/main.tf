module "nuke_everything_daily_midnight" {
  source = "github.com/binbashar/terraform-aws-lambda-nuke.git?ref=2.9.0"

  # Define name to use for lambda function, cloudwatch event and iam role"
  name        = "${var.project}-${var.environment}-cloud-nuke-everything"
  kms_key_arn = data.terraform_remote_state.keys.outputs.aws_kms_key_arn

  # Define the aws cloudwatch event rule schedule expression,
  # eg1: monday to friday at 22hs cron(0 22 ? * MON-FRI *)
  # eg2: once a week every friday at 00hs cron(0 00 ? * FRI *)
  # eg3: everyday at 00hs cron(0 00 * * ? *)
  cloudwatch_schedule_expression = "cron(0 00 * * ? *)"

  # Define the resources that will not be destroyed, eg: key_pair,eip,
  # network_security,autoscaling,ebs,ec2,ecr,eks,elasticbeanstalk,elb,spot,
  # dynamodb,elasticache,rds,redshift,cloudwatch,endpoint,efs,glacier,s3"
  exclude_resources = "cloudwatch,key_pair,s3,dynamodb,vpc"

  # Only destroy resources that were created before a certain period,
  # eg: 0d, 1d, ... ,7d etc
  older_than = "0d"
}


