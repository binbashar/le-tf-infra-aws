#
# AWS Provider Settings
#
variable "region" {
    description = "AWS Region"
}

variable "profile" {
    description = "AWS Profile"
}

#
# Project Variables
#

variable "environment" {
    description = "Environment Name"
}

variable "bucket" {}

#
# External Accounts Data
#
variable "dev_account_id" {
    description = "Dev/Stage Account ID"
}
variable "security_account_id" {
    description = "Account: Security & Users Management"
}
variable "shared_account_id" {
    description = "Account: Shared Resources"
}

#
# Compute
#
variable "aws_ami_os_id" {
    description = "AWS AMI Operating System Identificator"
    default = "ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*"
}

variable "aws_ami_os_owner" {
    description = "AWS AMI Operating System Owner"
    default = "099720109477"
}

variable "instance_type" {
    description = "AWS EC2 Instance Type"
    default = "t3.small"
}