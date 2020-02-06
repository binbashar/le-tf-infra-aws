#
# config/backend.config
#
#================================#
# Terraform AWS Backend Settings #
#================================#
variable "region" {
  type        = string
  description = "AWS Region"
}

variable "profile" {
  type        = string
  description = "AWS Profile (required by the backend but also used for other resources)"
}

variable "bucket" {
  type        = string
  description = "AWS S3 TF State Backend Bucket"
}
variable "dynamodb_table" {
  type        = string
  description = "AWS DynamoDB TF Lock state table name"
}
variable "encrypt" {
  type        = bool
  description = "Enable AWS DynamoDB with server side encryption"
}

#
# config/base.config
#
#=============================#
# Project Variables           #
#=============================#
variable "project" {
  type        = string
  description = "Project Name"
}

variable "project_long" {
  type        = string
  description = "Project Long Name"
}

variable "environment" {
  type        = string
  description = "Environment Name"
}

#
# config/extra.config
#
#=============================#
# Accounts & Extra Vars       #
#=============================#
variable "region_secondary" {
  type        = string
  description = "AWS Scondary Region for HA"
}

variable "security_account_id" {
  type        = string
  description = "Account: Security & Users Management"
}

variable "shared_account_id" {
  type        = string
  description = "Account: Shared Resources"
}

variable "appsdevstg_account_id" {
  type        = string
  description = "Account: Dev Modules & Libs"
}

variable "appsprd_account_id" {
  type        = string
  description = "Account: Prod Modules & Libs"
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
  default     = "cloudwatch,key_pair,s3,dynamodb,vpc"
}

variable "older_than" {
  description = "Only destroy resources that were created before a certain period, eg: 0d, 1d, ... ,7d etc"
  type        = string
  default     = "0d"
}
