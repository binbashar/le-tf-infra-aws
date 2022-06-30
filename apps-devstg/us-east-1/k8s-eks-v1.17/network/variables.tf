#===========================================#
# Networking                                #
#===========================================#
variable "vpc_shared_created" {
  description = "true if Shared account EKS VPC exists and needs DNS association"
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
  default     = false
}

variable "vpc_vault_hvn_peering_connection_id" {
  description = "Hahicorp Vault Cloud HVN VPC peering ID"
  type        = string
  default     = "pcx-0c270c9be265da78d"
}

variable "vpc_vault_hvn_cidr" {
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

variable "enable_kms_endpoint" {
  description = "Enable KMS endpoint"
  type        = bool
  default     = false
}

variable "enable_kms_endpoint_private_dns" {
  description = "Enable KMS endpoint"
  type        = bool
  default     = false
}
