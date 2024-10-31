variable "project" {
  description = "The project name"
  type        = string
}

variable "vpc_name_suffix" {
  description = "The suffix to form the vpc name like {var.project}-{var.environment}-vpc-{var.vpc_name_suffix}"
  type        = string
}

variable "environment" {
  description = "The environment name"
  type        = string
}

variable "vpc_cidr" {
  description = "The VPC CIDR"
  type        = string
}

variable "availability_zones" {
  description = "The letter for the AZ, e.g. [\"a\", \"b\"] (max 4 zones)"
  type        = list
  default     = ["a", "b"]
}

variable "region" {
  description = "The AWS region"
  type        = string
}

variable "subnet_bits" {
  description = "The subnet bits to define the subnets"
  type        = number
  default     = 2
}

variable "create_public_subnet" {
  description = "True to create public subnets"
  type        = bool
  default     = true
}

variable "create_private_subnet" {
  description = "True to create private subnets"
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

variable "create_vpc_peerings_for_shared_vpcs" {
  description = "Create the vpc peerings to shared vpcs (default or ovewriten by `shared_vpcs`). `create_acl_for_shared_vpcs` has to be `true`."
  type        = bool
  default     = true
}

variable "create_acl_for_shared_vpcs" {
  description = "Create the inbound rules to allow traffic from shared vpcs (default or ovewriten by `shared_vpcs`)"
  type        = bool
  default     = true
}

variable "shared_vpcs" {
  description = "VPC to receive data from. E.g. { \"vpcname\" => [ \"172.18.0.0/21\"]}. Used to fill the private ACL inbound rules. `create_acl_for_shared_vpcs` has to be `true`."
  type        = map(list(string))
  default     = null
}

variable "create_acl_for_vpn_ip" {
  description = "Create the inbound rules to allow traffic from VPN Server Private IP (default or ovewriten by `vpn_private_ip`)"
  type        = bool
  default     = true
}
variable "vpn_private_ip" {
  description = "The VPN server private IP"
  type        = string
  default     = null
  validation {
    condition     = can(regex("^[1-9]+\\.[1-9]+\\.[1-9]+\\.[1-9]+$", var.vpn_private_ip)) || var.vpn_private_ip == null
    error_message = "Must be a valid IPv4 CIDR block address."
  }
}

variable "additional_private_acl_rules" {
  description = "Additional private ACL rules"
  type        = list(object({
      rule_number = number
      rule_action = string
      from_port   = number
      to_port     = number
      protocol    = string
      cidr_block  = string
  }))
  default     = null
}

variable "additional_acl_rules" {
  description = "Additional default ACL rules"
  type        = list(object({
      rule_number = number
      rule_action = string
      from_port   = number
      to_port     = number
      protocol    = string
      cidr_block  = string
  }))
  default     = null
}

variable "private_subnet_tags" {
  description = "Tags for the private subnets"
  type        = map(string)
  default     = null
}

variable "public_subnet_tags" {
  description = "Tags for the public subnets"
  type        = map(string)
  default     = null
}

variable "tags" {
  description = "Tags"
  type        = map(string)
  default     = null
}

variable "route53_private_zone_to_associate" {
  description = "Private Route53 DNS zone to associate to the new VPC"
  type        = string
  default     = null
}

variable "enable_s3_dynamodb_vpce" {
  description = "Enable VPC for S3 and Dynamodb in the VPC"
  type        = bool
  default     = true
}

variable "enable_flow_logs" {
  description = "Enable Flow Logs"
  type        = bool
  default     = false
}

variable "accept_traffic_from_public_shared" {
  description = "Whether to accept traffic from public shared subnets"
  type        = bool
  default     = true
}

variable "accept_traffic_from_private_shared" {
  description = "Whether to accept traffic from private shared subnets"
  type        = bool
  default     = true
}

variable "shared-base-terraform-background-key" {
  description = "Whether to override the default shared base network terraform backend key"
  type        = string
  default     = "shared/network/terraform.tfstate"
}

variable "shared-base-terraform-background-region" {
  description = "Whether to override the default shared base network terraform backend region"
  type        = string
  default     = null
}
