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
}

#===========================================#
# Accounts                                  #
#===========================================#
variable "shared_account_id" {
  description = "Account: Shared Resources"
}

#===========================================#
# External Accounts Data                    #
#===========================================#
variable "security_account_id" {
  description = "Security & Users Management Account ID"
}

variable "dev_account_id" {
  description = "Dev/Stage Account ID"
}

#===========================================#
# DNS                                       #
#===========================================#
#
# Public Hosted DNS Zones
#
variable "aws_public_hosted_zone_fqdn_1" {
  description = "AWS Route53 public hosted zone fully qualified domain name (fqdn)"
  default     = "binbash.com.ar"
}

#
# A records
#
variable "aws_public_hosted_zone_fqdn_record_name_1" {
  description = "AWS Route53 public hosted zone fully qualified domain name (fqdn)"
  default     = "www.binbash.com.ar"
}

variable "aws_public_hosted_zone_1_address_record_1" {
  description = "AWS Route53 public hosted zone A type record"
  default     = "35.227.27.193"
}

variable "aws_public_hosted_zone_fqdn_record_name_2" {
  description = "AWS Route53 public hosted zone fully qualified domain name (fqdn)"
  default     = "jenkins.binbash.com.ar"
}

variable "aws_public_hosted_zone_1_address_record_2" {
  description = "AWS Route53 public hosted zone A type record"
  default     = "35.227.116.126"
}

variable "aws_public_hosted_zone_fqdn_record_name_3" {
  description = "AWS Route53 public hosted zone fully qualified domain name (fqdn)"
  default     = "passbolt.binbash.com.ar"
}

variable "aws_public_hosted_zone_1_address_record_3" {
  description = "AWS Route53 public hosted zone A type record"
  default     = "35.190.149.186"
}

#
# TXT records
#
# Google
variable "aws_public_hosted_zone_1_text_record_2_name" {
  description = "AWS Route53 public hosted zone TXT type record"
  default     = "google._domainkey.binbash.com.ar."
}
variable "aws_public_hosted_zone_1_text_record_1" {
  description = "AWS Route53 public hosted zone TXT type record"
  default     = "v=spf1 include:_spf.google.com ~all"
}
variable "aws_public_hosted_zone_1_text_record_2" {
  description = "AWS Route53 public hosted zone TXT type record"
  default     = "v=DKIM1; k=rsa; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQCJSOC7xBao4tKZyBpQo8fLBs36VJc5Rm+Fy0FJHQdJTzdQ1wlBpJx7nlKf/7iHSW+0N5082sgaB4HzaOkGH6FQvf5h7LbnYZxpaRis/xOU6jr2NJltG30kLQGnsWcCbC+nfpgf0lojifNPSvVbk1TDs1aNzf6rXENATtUIrV/8yQIDAQAB"
}

# Github
variable "aws_public_hosted_zone_1_text_record_3_name" {
  description = "AWS Route53 public hosted zone TXT type record"
  default     = "_github-challenge-binbashar.binbash.com.ar."
}
variable "aws_public_hosted_zone_1_text_record_3" {
  description = "AWS Route53 public hosted zone TXT type record"
  default     = "86e25ec336"
}

# MailChimp
variable "aws_public_hosted_zone_1_text_record_4_name" {
  description = "AWS Route53 public hosted zone TXT type record"
  default     = "k1._domainkey.binbash.com.ar"
}
variable "aws_public_hosted_zone_1_text_record_4" {
  description = "AWS Route53 public hosted zone TXT type record"
  default     = "dkim.mcsv.net"
}
variable "aws_public_hosted_zone_1_text_record_5_name" {
  description = "AWS Route53 public hosted zone TXT type record"
  default     = "binbash.com.ar"
}
variable "aws_public_hosted_zone_1_text_record_5" {
  description = "AWS Route53 public hosted zone TXT type record"
  default     = "v=spf1 include:servers.mcsv.net ?all"
}

#
# MX Records
#
variable "aws_public_hosted_zone_1_mail_servers_1" {
  description = "AWS Route53 public hosted zone MX type record"
  default     = "10 ALT4.ASPMX.L.GOOGLE.COM"
}

variable "aws_public_hosted_zone_1_mail_servers_2" {
  description = "AWS Route53 public hosted zone MX type record"
  default     = "1 ASPMX.L.GOOGLE.COM"
}

variable "aws_public_hosted_zone_1_mail_servers_3" {
  description = "AWS Route53 public hosted zone MX type record"
  default     = "5 ALT1.ASPMX.L.GOOGLE.COM"
}

variable "aws_public_hosted_zone_1_mail_servers_4" {
  description = "AWS Route53 public hosted zone MX type record"
  default     = "5 ALT2.ASPMX.L.GOOGLE.COM"
}

variable "aws_public_hosted_zone_1_mail_servers_5" {
  description = "AWS Route53 public hosted zone MX type record"
  default     = "10 ALT3.ASPMX.L.GOOGLE.COM"
}

#
# Private Hosted DNS Zones
#
variable "aws_private_hosted_zone_fqdn_1" {
  description = "AWS Route53 private hosted zone fully qualified domain name (fqdn)"
  default     = "aws.binbash.com.ar"
}
