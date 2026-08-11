# #------------------------------------------------------------------------------
# # WAFv1 GLOBAL Config
# #------------------------------------------------------------------------------
enable_wafv1_global = false

# #------------------------------------------------------------------------------
# # WAFv1 REGIONAL Config
# #------------------------------------------------------------------------------
enable_wafv1_regional = false

# #------------------------------------------------------------------------------
# # WAFv2 REGIONAL Config
# #------------------------------------------------------------------------------
enable_wafv2_regional = true

# #------------------------------------------------------------------------------
# # ALB WAF Demo Config
# #------------------------------------------------------------------------------
# Off. This block provisions a throwaway internal ALB whose only purpose is to
# give the WebACL something to associate with, and it also drives
# `create_alb_association` in wafv2-regional.tf. The ALB this WebACL actually
# guards is the one the Load Balancer Controller provisions for the public
# Envoy Gateway in `k8s-eks-demoapps/k8s-components`, and that association is
# made from the Ingress via `alb.ingress.kubernetes.io/wafv2-acl-arn` -- its ARN
# does not exist when this layer plans, and it changes on every cluster
# re-spin. So this layer only owns the WebACL; it never owns an association.
alb_waf_example = {
  enabled = false
  # Load balancer internal (true) or internet-facing (false)
  internal = true
  # Load balancer type: application or network
  type = "application"
}

# #------------------------------------------------------------------------------
# # ALB WAF SG Config
# #------------------------------------------------------------------------------
#Add your Public IP to Allow Traffic Inbound ["XXX.XXX.XXX.XXX/32"]
ingress_cidr_blocks = []
