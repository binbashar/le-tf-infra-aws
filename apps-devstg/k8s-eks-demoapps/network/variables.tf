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

variable "region_secondary" {
  description = "AWS Scondary Region for HA"
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

variable "appsdevstg_account_id" {
  type        = string
  description = "Account: Dev Modules & Libs"
}

variable "appsprd_account_id" {
  type        = string
  description = "Account: Prod Modules & Libs"
}

variable "network_account_id" {
  type        = string
  description = "Account: Network"
}

variable "vault_token" {
  type = string
}

variable "vault_address" {
  type = string
}

#===========================================#
# Networking                                #
#===========================================#
variable "vpc_apps_devstg_eks_created" {
  description = "true if Dev account EKS VPC is created for Peering purposes"
  type        = bool
  default     = true
}

variable "vpc_apps_devstg_eks_dns_assoc" {
  description = "true if Dev account EKS VPC exists and needs DNS association"
  type        = bool
  default     = true
}

variable "vpc_vault_hvn_created" {
  description = "true if the Hahicorp Vault Cloud HVN account VPC is created for Peering purposes"
  type        = bool
  default     = true
}

variable "vpc_vault_hvn_peering_connection_id" {
  description = "Hahicorp Vault Cloud HVN VPC peering ID"
  type        = string
  default     = "pcx-0c270c9be265da78d"
}

variable "vpc_vault_hvn_cird" {
  description = "Hahicorp Vault Cloud HVN VPC CIDR segment"
  type        = string
  default     = "172.25.16.0/20"
}

variable "vpc_enable_nat_gateway" {
  description = "Enable NAT Gatewway"
  type        = bool
  default     = false
}

variable "vpc_single_nat_gateway" {
  description = "Single NAT Gatewway"
  type        = bool
  default     = true
}

variable "vpc_enable_dns_hostnames" {
  description = "Enable DNS HOSTNAME"
  type        = bool
  default     = true
}

variable "vpc_enable_vpn_gateway" {
  description = "Enable VPN Gateway"
  type        = bool
  default     = false
}

variable "vpc_endpoints" {
  description = "VPC endpoints"
  type        = any
  default = {
    s3 = {
      service      = "s3"
      service_type = "Gateway"
    }
    dynamodb = {
      service      = "dynamodb"
      service_type = "Gateway"
    }
  }
}
