#===========================================#
# Networking                                #
#===========================================#
variable "vpc_shared_created" {
  description = "true if Shared account VPC is created for Peering purposes"
  type        = bool
  default     = true
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

variable "enable_ssm_endpoints" {
  description = "Enable SSM endpoints"
  type        = bool
  default     = false
}

variable "enable_ssm_endpoints_private_dns" {
  description = "Enable SSM endpoints"
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
