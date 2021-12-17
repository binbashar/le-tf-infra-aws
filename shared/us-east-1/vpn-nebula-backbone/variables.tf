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

variable "root_account_id" {
  type        = string
  description = "Account: Root"
}

variable "security_account_id" {
  type        = string
  description = "Account: Security & Users Management"
}

variable "shared_account_id" {
  type        = string
  description = "Account: Shared Resources"
}

variable "network_account_id" {
  type        = string
  description = "Account: Networking Resources"
}

variable "appsdevstg_account_id" {
  type        = string
  description = "Account: Dev Modules & Libs"
}

variable "appsprd_account_id" {
  type        = string
  description = "Account: Prod Modules & Libs"
}

#
# EC2 Attributes
#
variable "aws_ami_os_name" {
  type        = string
  description = "AWS AMI Operating System Identificator"
  default     = "ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"
}

variable "aws_ami_owner" {
  type        = string
  description = "The AWS account ID of the image owner, eg: 099720109477 for Canonical "
  default     = "099720109477"
}

variable "ec2_instance_type" {
  type        = string
  description = "EC2 instance type"
  default     = "t2.medium"
}

variable "ec2_instances_count" {
  type        = number
  description = "EC2 instance count"
  default     = "2"
}

#
# Layer variables
#
variable "allowed_ips_udp" {
  type        = list(string)
  description = "List of allowed IPs to access UDP 3000"
  default     = ["190.195.47.88/32"]
}

variable "allowed_ips_ssh" {
  type        = list(string)
  description = "List of allowed IPs to access SSH"
  default     = ["190.195.47.88/32"]
}

variable "allowed_ssh_keys" {
  type        = list(string)
  description = "List of allowed keys to access throught SSH"
  default     = ["ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDAE5Sv6dySC97s2Y0pdIdtTumM0yrKuEccobQwxL818lEtCIhMYTZX1aX9u9bOfIpjYzSO6HazT+9UGPI96mL45X+xZKBSvqsN/Mx1oUxGIZBIvX7CN7g5Sio+lkCOsKaxV3j/yK4JndvC5sUOIFJWUtPW+sWkpEizXGly50K7vza7XnJ6xHbJf1zNQA5S7/Dfm9fjlmD/jX38U4efHmypFUyVmE5Me6NG8naFYgN8DEURzPZklZJgAdgkSDMkqLYNQjXHE9gcs5Eud5WVtrpYy5utCp6on7EKcodD6uz4GjxWyFqbgFAkgmPpKFUnAxoTcgEm2xTp9ApSNshZnz+IfSTAEz75DWpW4CWE7Ka1Qyl1d6EilDv9gVFheuT08WbZU1I1iyB54+1vLzrArsf+CRU6UfS4Kk8u2GhKHeI64eOc6j56U92ce6zsLAqCnwnDMZUve3yT/bbBuRrDBoS2M/DufNxCZjvSH54/pIcfdlbEyHtQTFBhfT+ccxjc1k0= jose.peinado@binbash.com.ar"]
}