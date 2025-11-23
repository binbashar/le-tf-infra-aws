#===========================================#
# Transit Gateway                           #
#===========================================#

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
