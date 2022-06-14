
variable "enable_vpc_attach" {
  description = "Enable VPC attachments per account"
  type        = any
  default = {
    network     = false
    shared      = false
    apps-devstg = false
    apps-prd    = false
  }
}

variable "enable_network_firewall" {
  description = "Enable AWS Network Firewall support"
  type        = bool
  default     = false
}

variable "vpn_gateway_amazon_side_asn" {
  description = "The Autonomous System Number (ASN) for the Amazon side of the gateway. By default the virtual private gateway is created with the current default Amazon ASN."
  type        = number
  default     = 64512
}
