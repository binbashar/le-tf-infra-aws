#===========================================#
# Project Variables                         #
#===========================================#
variable "project" {
  description = "Project Name"
}

variable "project_long" {
  description = "Project Name Complete"
}

variable "environment" {
  description = "Environment Name"
}

variable "security_account_id" {}
variable "shared_account_id" {}
variable "dev_account_id" {}

variable "bucket" {}
variable "dynamodb_table" {}
variable "encrypt" {}

variable "cloudtrail_org_bucket" {}

#=============================#
# EC2 BASIC LAYOUT MODULE     #
#=============================#
#
# General
#
variable "prefix" {
  type        = string
  description = "Prefix"
  default     = "infra"
}

variable "name" {
  type        = string
  description = "Name"
  default     = "pritunl-vpn"
}

#
# EC2 Attributes
#
variable "aws_ami_os_id" {
  description = "AWS AMI Operating System Identificator"
  default     = "ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*"
}

variable "aws_ami_os_owner" {
  description = "AWS AMI Operating System Owner, eg: 099720109477 for Canonical "
  default     = "099720109477"
}

variable "instance_type" {
  type        = string
  description = "EC2 Instance Type"
  default     = "t3.micro"
}

variable "ebs_optimized" {
  type        = string
  description = "Enable EBS Optimized"
  default     = "false"
}

variable "associate_public_ip_address" {
  type        = bool
  description = "Associate a public IP address with the instance"
  default     = true
}

variable "root_device_backup_tag" {
  type        = string
  description = "EC2 Root Block Device backup tag"
  default     = "True"
}

variable "monitoring" {
  type        = bool
  description = "If true, the launched EC2 instance will have detailed monitoring enabled"
  default     = true
}
