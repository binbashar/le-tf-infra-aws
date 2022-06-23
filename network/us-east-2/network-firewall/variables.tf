#===========================================#
# Networking                                #
#===========================================#
variable "vpc_apps_devstg_created" {
  description = "true if Apps Dev account VPC is created for Peering purposes"
  type        = bool
  default     = true
}

variable "vpc_apps_devstg_eks_created" {
  description = "true if Apps Dev account EKS VPC is created for Peering purposes"
  type        = bool
  default     = true
}

variable "vpc_apps_prd_created" {
  description = "true if Apps Prd account VPC is created for Peering purposes"
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
  default     = "pcx-0109e4ef7e784ee06"
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

variable "vpc_enable_s3_endpoint" {
  description = "Enable S3 endpoint"
  type        = bool
  default     = true
}

variable "vpc_enable_dynamodb_endpoint" {
  description = "Enable DynamoDB endpoint"
  type        = bool
  default     = true
}

variable "enable_kms_endpoint" {
  description = "Enable KMS endpoint"
  type        = bool
  default     = false
}

variable "manage_default_network_acl" {
  description = "Manage default Network ACL"
  type        = bool
  default     = false
}

variable "public_dedicated_network_acl" {
  description = "Manage default Network ACL"
  type        = bool
  default     = true
}

variable "private_dedicated_network_acl" {
  description = "Manage default Network ACL"
  type        = bool
  default     = true
}

variable "enable_network_firewall" {
  description = "Enable AWS Network Firewall support"
  type        = bool
  default     = false
}
