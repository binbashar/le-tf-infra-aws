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
  default     = "t3.micro"
}

#=============================#
# Storage                     #
#=============================#
variable "volume_size" {
  description = "EBS volume size"
  default     = 16
}

#=============================#
# Security                    #
#=============================#

#
# SG private for aws org CIDR
#
variable "sg_private_name" {
  description = "Security group name"
  default     = "vpn-private"
}

// 22   ssh
// 9100 prometheus node exporter
// 443 https for vpc org cird
variable "sg_private_tpc_ports" {
  description = "Security group TCP ports"
  default     = "22,443,9100"
}

variable "sg_private_udp_ports" {
  description = "Security group UDP ports"
  default     = "15255"
}

variable "sg_private_cidrs" {
  description = "Security group CIDR segments"
  default     = "172.17.0.0/20"
}

#
# SG public for www (0.0.0.0/0)
#
variable "sg_public_name" {
  description = "Security group name"
  default     = "vpn-public"
}

// 80    pritunl.web.letsencrypt
// 15255 pritunl.server.admin
// 15255 pritunl.server.devops
variable "sg_public_tpc_ports" {
  description = "Security group TCP ports"
  default     = "80"
}

variable "sg_public_udp_ports" {
  description = "Security group UDP ports"
  default     = "15255,15256"
}

variable "sg_public_cidrs" {
  description = "Security group CIDR segments"
  default     = "0.0.0.0/0"
}

#
# SG public temporary
#
variable "sg_public_temporary_enabled" {
  description = "set to 1 to create SG for temporary public access"
  default     = 1
}

variable "sg_public_temporary_name" {
  description = "Security group name"
  default     = "vpn-public-temp-access"
}

variable "sg_public_temporary_tpc_ports" {
  type        = "list"
  description = "Security group TCP ports"
  default     = ["22", "443"]
}

variable "sg_public_temporary_cidrs" {
  description = "Security group CIDR segments"
  default     = "0.0.0.0/0"
}

#
# Provisioner Connections
#
variable "provisioner_user" {
  description = "username - for SSH connection"
  default     = "ubuntu"
}

variable "shell_cmds" {
  description = "A comma separated string of shell commands - eg: [echo 'hellow world',ls]"
  default     = "sudo apt-get update,echo 'ANSIBLE PROVISION WILL START SOON'"
}

variable "provisioner_private_key_path" {
  description = "private_key path - The contents of an SSH key to use for the connection. These can be loaded from a file on disk using the file func."
  default     = "./provisioner/keys/id_rsa"
}

variable "provisioner_private_key_relative_script_path" {
  description = "private_key relative path - The contents of an SSH key to use for the connection. These can be loaded from a file on disk using the file func."
  default     = "../keys/id_rsa"
}

variable "provisioner_script_path" {
  description = "ansible-playbook path."
  default     = "./provisioner/ansible-playbook"
}

variable "provisioner_script_tags_enable" {
  description = "Use tags in ansible provisioner if set to True, otherwise don't use any specific tag"
  default     = "false"
}

variable "provisioner_script_tags" {
  description = "An space separated ansible-playbook tags list"
  default     = "security-users"
}

variable "provisioner_vault_pass_enabled" {
  description = "Use --vault-password-file in ansible provisioner if set to True, otherwise don't use this flag"
  default     = "true"
}

variable "provisioner_vault_pass_path" {
  description = "ansible-vault secret decyption pass."
  default     = "./group_vars/.vault_pass"
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
  default     = "vpn.binbash.com.ar"
}

variable "instance_dns_record_name_2_enabled" {
  description = "Route53 DNS record name if set to true, otherwise don't use any specific tag"
  default     = "true"
}

variable "instance_dns_record_name_2" {
  description = "AWS EC2 Instance Type"
  default     = "webhooks.binbash.com.ar"
}
