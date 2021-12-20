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

#
# Layer variables
#

# Number of instances to be launched
variable "ec2_instances_count" {
  type        = number
  description = "EC2 instance count"
  default     = "2"
}

# List of IPs allowed to access throught the UDP port 3000
variable "allowed_ips_udp" {
  type        = list(string)
  description = "List of allowed IPs to access UDP 3000"
  default     = ["190.195.47.88/32"]
}

# List of IPs allowed to access throught the SSH port 22
variable "allowed_ips_ssh" {
  type        = list(string)
  description = "List of allowed IPs to access SSH"
  default     = ["190.195.47.88/32"]
}

# List of SSH public keys allowed to access to EC2 instances.
# Each key will be added as a entry on /home/ubuntu/.ssh/authorized_keys
variable "allowed_ssh_keys" {
  type        = list(string)
  description = "List of allowed keys to access throught SSH"
  default     = ["ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCxgBHFvzt0Hq9X/oQJp70vat3QMPiVb4R7/SVA8dHE/So3wF76hUDk2ZanRe1yPqjjzgQg0iUALWyscQ+8lOwzWM5ZMpjSqO637c2AjB+vWeyxxHVKzeBM/X6jWCnCMmjPNP/sb/nFrWVy5/9RoTSsRfwBO1muSlU2p6mSAAc5XA8yhuKjPdHq42oWcf/Uk5LbYxGurJe96o3rGUX9hwZHoTaXL/sx4nwfu3l96DZ0mJmdOg9YvMwgkNnjPKE1AcqxyIisakSo+tInYFwq5ySkTcWnAHqAYiUatCmFsAIlpD6vMsYqB2QDFdjFixBkkrf6DuYEf4t5HnQB+dF9qJBvtUvvJ1VsY1BNe8+oj8QRBfUmZKizrCFAeXMms8T6CyBfXDuLFIVok7UiALotZ5LYHnyXInAWYJ2EKnbLhk42tqcv2q+ddSWuwZfnKHOO3x2ukNQRSR+Z/IAQ9JAn63ylwAZFB8MLvuSVZlwIEMzuj88kZH25z+e8Nr1x+9pyCx8= jose.peinadorrrr@binbash.com.ar"]
}