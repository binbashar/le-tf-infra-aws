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

variable "environment" {
  description = "Environment Name"
}

#===========================================#
# Lambda Nuke                               #
#===========================================#
variable "cloudwatch_schedule_expression" {
  description = "Define the aws cloudwatch event rule schedule expression, eg: everyday at 22hs cron(0 22 ? * MON-FRI *)"
  type        = string
  default     = "cron(0 00 ? * FRI *)"
}

variable "name" {
  description = "Define name to use for lambda function, cloudwatch event and iam role"
  type        = string
  default     = "cloud-nuke-everything"
}

variable "exclude_resources" {
  description = "Define the resources that will not be destroyed, eg: key_pair,eip,network_security,autoscaling,ebs,ec2,ecr,eks,elasticbeanstalk,elb,spot,dynamodb,elasticache,rds,redshift,cloudwatch,endpoint,efs,glacier,s3"
  type        = string
  default     = "s3,dynamodb,vpc"
}

variable "older_than" {
  description = "Only destroy resources that were created before a certain period, eg: 0d, 1d, ... ,7d etc"
  type        = string
  default     = "0d"
}
