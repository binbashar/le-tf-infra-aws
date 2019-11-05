#===========================================#
# AWS Provider Settings                     #
#===========================================#
variable "region" {
  description = "AWS Region"
}

variable "profile" {
  description = "AWS Profile"
}

#===========================================#
# Project Variables                         #
#===========================================#
variable "project" {
  description = "Project Name"
}

variable "project_long" {
  description = "Project Long Name"
}

variable "environment" {
  description = "Environment Name"
  default     = "dev"
}

#===========================================#
# Accounts                                  #
#===========================================#
variable "cloudwatch_schedule_expression" {
  description = "Define the aws cloudwatch event rule schedule expression, eg: everyday at 22hs cron(0 22 ? * MON-FRI *)"
  type        = string
  default     = "cron(0 00 ? * FRI *)"
}

variable "name" {
  description = "Define name to use for lambda function, cloudwatch event and iam role"
  type        = string
  default     = "cloud_nuke_everything"
}

variable "custom_iam_role_arn" {
  description = "Custom IAM role arn for the scheduling lambda"
  type        = string
  default     = null
}

variable "exclude_resources" {
  description = "Define the resources that will not be destroyed, eg: key_pair,autoscaling,ebs,ec2,ecr,eks,elasticbeanstalk,elb,spot,dynamodb,elasticache,rds,redshift,cloudwatch,endpoint,efs,glacier,s3"
  type        = string
  default     = "s3,dynamo,vpc"
}

variable "older_than" {
  description = "Only destroy resources that were created before a certain period"
  type        = string
  default     = "7d"
}
