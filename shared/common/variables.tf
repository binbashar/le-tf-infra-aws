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
variable "project" {
    description = "Project Name"
}
variable "environment" {
    description = "Environment Name"
}

#
# External Accounts Data
#
variable "security_account_id" {
    description = "Security & Users Management Account ID"
}
variable "dev_account_id" {
    description = "Dev/Stage Account ID"
}
variable "dev_vpc_id" {
    description = "VPC ID of Applications Dev/Stage Account"
}
variable "dev_vpc_cidr_block" {
    description = "VPC CIDR Block of Applications Dev/Stage Account"
}
variable "appsprd_account_id" {
    description = "Production Account ID"
}
variable "appsprd_vpc_id" {
    description = "VPC ID of Applications Production Account"
}
variable "appsprd_vpc_cidr_block" {
    description = "VPC CIDR Block of Applications Production Account"
}
variable "dev_internal_zone_id" {
    description = "Internal DNS zone for Applications Dev/Stage kubernetes"
}
variable "appsprd_internal_zone_id" {
    description = "Internal DNS zone for Applications Production kubernetes"
}
variable "shared_account_id" {
    description = "ID account for shared aws"
}

# AWS Config

variable "bucket_prefix" {
  default = "config"
}

variable "bucket_key_prefix" {
  default = "config"
}

variable "sns_topic_arn" {
  default = ""
}

variable "tags" {
  default = {
    "owner"   = "bbshared-account"
    "project" = "config-sharedbb"
    "client"  = "bbInternal"
  }
}


variable "reports_key_prefix" {
  default = "reports"
}