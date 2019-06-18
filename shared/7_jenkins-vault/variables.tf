#=============================#
# AWS Provider Settings       #
#=============================#
variable "region" {
  description = "AWS Region"
}

variable "profile" {
  description = "AWS Profile"
}

#=============================#
# Project Variables           #
#=============================#
variable "environment" {
  description = "Environment Name"
}

#=============================#
# External Accounts Data      #
#=============================#
variable "dev_account_id" {
  description = "Dev/Stage Account ID"
}

variable "security_account_id" {
  description = "Account: Security & Users Management"
}

variable "shared_account_id" {
  description = "Account: Shared Resources"
}

#=============================#
# Compute                     #
#=============================#
variable "aws_ami_os_id" {
  description = "AWS AMI Operating System Identificator"
  default     = "ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*"
}

variable "aws_ami_os_owner" {
  description = "AWS AMI Operating System Owner"
  default     = "099720109477"
}

variable "instance_type" {
  description = "AWS EC2 Instance Type"
  default     = "t3.small"
}

#=============================#
# Storage                     #
#=============================#
#
# EBS
#
variable "volume_size_root" {
  description = "EBS volume size"
  default     = 20
}

variable "volume_size_extra_1" {
  description = "EBS volume size"
  default     = 100
}

variable "volume_size_extra_2" {
  description = "EBS volume size"
  default     = 100
}

#
# S3
#
variable "aws_s3_bucket_1_enabled" {
  description = "AWS S3 bucket will be created if set to true, otherwise don't"
  default     = "true"
}

variable "aws_s3_bucket_name_1" {
  description = "AWS S3 bucket name"
  default     = "bb-shared-vault-storage"
}

variable "aws_s3_bucket_2_enabled" {
  description = "AWS S3 bucket will be created if set to true, otherwise don't"
  default     = "true"
}

variable "aws_s3_bucket_name_2" {
  description = "AWS S3 bucket name"
  default     = "bb-shared-ssl-certificates"
}

#=============================#
# Security                    #
#=============================#

#
# SG private for aws org CIDR
#
variable "sg_private_name" {
  description = "Security group name"
  default     = "jenkins-vault-private"
}

// 22   ssh
// 80   http jenkins
// 443  https jenkins
// 8080 http jenkins default
// 8200 hashicorp vault
// 9100 prometheus node exporter
variable "sg_private_tpc_ports" {
  description = "Security group TCP ports"
  default     = "22,80,443,8080,8200,9100"
}

variable "sg_private_udp_ports" {
  description = "Security group UDP ports"
  default     = "default_null"
}

variable "sg_private_cidrs" {
  description = "Security group CIDR segments"
  default     = "172.17.0.0/20"
}

#=============================#
# Provisioner: aws userdata   #
#=============================#
variable "aws_userdata_path" {
  description = "AWS EC2 userdata provisioning script path"
  default     = "./provisioner/aws-userdata/userdata.sh"
}

#=============================#
# DNS                         #
#=============================#
variable "instance_dns_record_name_1_enabled" {
  description = "Route53 DNS record name if set to true, otherwise don't use any specific tag"
  default     = "true"
}

variable "instance_dns_record_name_1" {
  description = "AWS EC2 Instance Type"
  default     = "jenkins.aws.binbash.com.ar"
}

variable "instance_dns_record_name_2_enabled" {
  description = "Route53 DNS record name if set to true, otherwise don't use any specific tag"
  default     = "true"
}

variable "instance_dns_record_name_2" {
  description = "AWS EC2 Instance Type"
  default     = "vault.aws.binbash.com.ar"
}

// https://www.bennadel.com/blog/3420-obtaining-a-wildcard-ssl-certificate-from-letsencrypt-using-the-dns-challenge.htm
//Please deploy a DNS TXT record under the name
//_acme-challenge.aws.binbash.com.ar with the following value
variable "letsencrypt_dns_record_name_enabled" {
  description = "Route53 DNS record name if set to true, otherwise don't use any specific tag"
  default     = "true"
}

variable "letsencrypt_dns_record_name" {
  description = "AWS EC2 Instance Type"
  default     = "_acme-challenge.aws.binbash.com.ar"
}

variable "letsencrypt_dns_record_value" {
  description = "AWS EC2 Instance Type"
  default     = "UQ6h7YpwtBLE6GvRgPB7zqwqvLuWxcIibnq9h8Qalmo"
}
