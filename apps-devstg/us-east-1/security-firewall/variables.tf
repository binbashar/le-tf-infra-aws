#================================#
# Local variables                #
#================================#
variable "enable_wafv1_global" {
  type    = bool
  default = false
}

variable "enable_wafv1_regional" {
  type    = bool
  default = false
}

variable "enable_wafv2_regional" {
  type    = bool
  default = false
}

variable "alb_waf_example" {
  type    = any
  default = {}
}

variable "ingress_cidr_blocks" {
  description = "List of IPv4 CIDR ranges to use on all ingress rules"
  type        = list(string)
  default     = []
}
