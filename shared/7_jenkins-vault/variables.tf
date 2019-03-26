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
# Network
#=============================#
variable "aws_vpc_id" {
    description = "AWS VPC id"
}
variable "aws_route53_internal_zone_id" {
  type = "list"
  description = "List of DNS Route53 internal hosted zones ID"
  default = []
}

#=============================#
# Storage                     #
#=============================#
variable "volume_size_root" {
  description = "EBS volume size"
  default = 20
}
variable "volume_size_extra_1" {
  description = "EBS volume size"
  default = 100
}
variable "volume_size_extra_2" {
  description = "EBS volume size"
  default = 100
}

#=============================#
# Security                    #
#=============================#

#
# SG private for aws org CIDR
#
variable "sg_private_name" {
  description = "Security group name"
  default = "jenkins-vault-private"
}
// 22   ssh
// 80   http jenkins
// 443  https jenkins
// 8200 hashicorp vault
// 8200 hashicorp vault
// 9100 prometheus node exporter
variable "sg_private_tpc_ports" {
  description = "Security group TCP ports"
  default = "22,80,443,8200,9100"
}
variable "sg_private_udp_ports" {
  description = "Security group UDP ports"
}
variable "sg_private_cidrs" {
  description = "Security group CIDR segments"
  default = "172.17.0.0/20"
}

#
# Provisioner Connections
#
variable "aws_key_pair_name" {
  description = "AWS ssh ec2 key pair name"
}

#=============================#
# DNS                         #
#=============================#
variable "instance_dns_record_name_1" {
    description = "AWS EC2 Instance Type"
    default     = "jenkins.aws.binbash.com.ar"
}
variable "instance_dns_record_name_2" {
    description = "AWS EC2 Instance Type"
    default     = "vault.aws.binbash.com.ar"
}

#=============================#
# TAGS                        #
#=============================#
variable "tags" {
  type = "map"
  description = "A mapping of tags to assign to all resources"
  default     = {}
}