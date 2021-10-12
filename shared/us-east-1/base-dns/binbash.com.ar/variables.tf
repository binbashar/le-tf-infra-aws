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

#===========================================#
# DNS                                       #
#===========================================#
#
# Public Hosted DNS Zones
#
variable "aws_public_hosted_zone_fqdn_1" {
  type        = string
  description = "AWS Route53 public hosted zone fully qualified domain name (fqdn)"
  default     = "binbash.com.ar"
}

#
# TXT records
#
# Google
variable "aws_public_hosted_zone_1_text_record_2_name" {
  type        = string
  description = "AWS Route53 public hosted zone TXT type record"
  default     = "google._domainkey.binbash.com.ar."
}
variable "aws_public_hosted_zone_1_text_record_2" {
  type        = string
  description = "AWS Route53 public hosted zone TXT type record"
  default     = "v=DKIM1; k=rsa; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQCJSOC7xBao4tKZyBpQo8fLBs36VJc5Rm+Fy0FJHQdJTzdQ1wlBpJx7nlKf/7iHSW+0N5082sgaB4HzaOkGH6FQvf5h7LbnYZxpaRis/xOU6jr2NJltG30kLQGnsWcCbC+nfpgf0lojifNPSvVbk1TDs1aNzf6rXENATtUIrV/8yQIDAQAB"
}

# Github
variable "aws_public_hosted_zone_1_text_record_3_name" {
  type        = string
  description = "AWS Route53 public hosted zone TXT type record"
  default     = "_github-challenge-binbashar.binbash.com.ar."
}
variable "aws_public_hosted_zone_1_text_record_3" {
  type        = string
  description = "AWS Route53 public hosted zone TXT type record"
  default     = "86e25ec336"
}

# MailChimp
variable "aws_public_hosted_zone_1_text_record_4_name" {
  type        = string
  description = "AWS Route53 public hosted zone TXT type record"
  default     = "k1._domainkey.binbash.com.ar"
}
variable "aws_public_hosted_zone_1_text_record_4" {
  type        = string
  description = "AWS Route53 public hosted zone TXT type record"
  default     = "dkim.mcsv.net"
}

#
# MX Records
#
variable "aws_public_hosted_zone_1_mail_servers_1" {
  type        = string
  description = "AWS Route53 public hosted zone MX type record"
  default     = "10 ALT4.ASPMX.L.GOOGLE.COM"
}

variable "aws_public_hosted_zone_1_mail_servers_2" {
  type        = string
  description = "AWS Route53 public hosted zone MX type record"
  default     = "1 ASPMX.L.GOOGLE.COM"
}

variable "aws_public_hosted_zone_1_mail_servers_3" {
  type        = string
  description = "AWS Route53 public hosted zone MX type record"
  default     = "5 ALT1.ASPMX.L.GOOGLE.COM"
}

variable "aws_public_hosted_zone_1_mail_servers_4" {
  type        = string
  description = "AWS Route53 public hosted zone MX type record"
  default     = "5 ALT2.ASPMX.L.GOOGLE.COM"
}

variable "aws_public_hosted_zone_1_mail_servers_5" {
  type        = string
  description = "AWS Route53 public hosted zone MX type record"
  default     = "10 ALT3.ASPMX.L.GOOGLE.COM"
}

#
# Private Hosted DNS Zones
#
variable "aws_private_hosted_zone_fqdn_1" {
  type        = string
  description = "AWS Route53 private hosted zone fully qualified domain name (fqdn)"
  default     = "aws.binbash.com.ar"
}

variable "aws_private_hosted_zone_apps_devstg_ec2_fleet_ansible_created" {
  type        = bool
  description = "Create Private DNS records for /apps-devstg/11_ec2_fleet_ansible instances"
  default     = false
}

#===========================================#
# DNS VPC Associations                      #
#===========================================#
variable "vpc_apps_devstg_dns_assoc" {
  type        = bool
  description = "true if Apps DevStg account VPC exists and needs DNS association"
  default     = true
}

variable "vpc_apps_devstg_eks_dns_assoc" {
  type        = bool
  description = "true if Apps DevStg account EKS VPC exists and needs DNS association"
  default     = true
}

variable "vpc_apps_devstg_kops_dns_assoc" {
  type        = bool
  description = "true if Apps DevStg account Kops Private Hosted Zone exists and needs DNS association"
  default     = true
}

variable "vpc_apps_prd_dns_assoc" {
  type        = bool
  description = "true if Apps Prd account VPC exists and needs DNS association"
  default     = true
}
