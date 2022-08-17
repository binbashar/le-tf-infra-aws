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