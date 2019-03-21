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
    default     = "t2.micro"
}

#=============================#
# Storage                     #
#=============================#
variable "volume_size" {
  description = "EBS volume size"
  default = 16
}

#=============================#
# Security                    #
#=============================#

#
# SG private for aws org CIDR
#
variable "sg_private_name" {
  description = "Security group name"
  default = "vpn-private"
}
// 22   ssh
// 9100 prometheus node exporter
// 443 https for vpc org cird
variable "sg_private_tpc_ports" {
  description = "Security group TCP ports"
  default = "22,443,9100"
}
variable "sg_private_udp_ports" {
  description = "Security group UDP ports"
  default = "15255"
}
variable "sg_private_cidrs" {
  description = "Security group CIDR segments"
  default = "172.17.0.0/20"
}

#
# SG public for www (0.0.0.0/0)
#
variable "sg_public_name" {
  description = "Security group name"
  default = "vpn-public"
}
// 80    pritunl.web.letsencrypt
// 11080 pritunl.server.admin
// 2709  pritunl.server.dev
// 15255 pritunl.server.dev
variable "sg_public_tpc_ports" {
  description = "Security group TCP ports"
  default = "80,2709,11080"
}
variable "sg_public_udp_ports" {
  description = "Security group UDP ports"
  default = "15255"
}
variable "sg_public_cidrs" {
  description = "Security group CIDR segments"
  default = "0.0.0.0/0"
}

#
# SG public temporary
#
variable "sg_public_temporary_enabled" {
    description = "set to 1 to create SG for temporary public access"
    default = 1
}
variable "sg_public_temporary_name" {
  description = "Security group name"
  default = "vpn-public-temp-access"
}
variable "sg_public_temporary_tpc_ports" {
  type = "list"
  description = "Security group TCP ports"
  default = ["22","443"]
}
variable "sg_public_temporary_cidrs" {
  description = "Security group CIDR segments"
  default = "0.0.0.0/0"
}

#
# Provisioner Connections
#
variable "provisioner_user" {
  description = "username - for SSH connection"
  default     = "ubuntu"
}
variable "provisioner_private_key_path" {
  description = "private_key path - The contents of an SSH key to use for the connection. These can be loaded from a file on disk using the file func."
  default     = "./provisioner/keys/id_rsa"
}
variable "provisioner_private_key_relative_script_path" {
  description = "private_key path - The contents of an SSH key to use for the connection. These can be loaded from a file on disk using the file func."
  default     = "../keys/id_rsa"
}
variable "provisioner_script_path" {
  description = "private_key path - The contents of an SSH key to use for the connection. These can be loaded from a file on disk using the file func."
  default     = "./provisioner/ansible-playbook"
}

#=============================#
# DNS                         #
#=============================#
variable "instance_dns_record_name_1" {
    description = "AWS EC2 Instance Type"
    default     = "vpn.binbash.com.ar"
}
variable "instance_dns_record_name_2" {
    description = "AWS EC2 Instance Type"
    default     = "webhooks.binbash.com.ar"
}

#=============================#
# TAGS                        #
#=============================#
variable "tags" {
  type = "map"
  description = "A mapping of tags to assign to all resources"
  default     = {}
}