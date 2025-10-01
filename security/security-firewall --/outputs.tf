output "wafv2_regional_alb_arn" {
  description = "The ARN of the WAFv2 WebACL"
  value       = module.wafv2_regional_alb.web_acl_arn
}

output "alb_waf_example_dns_name" {
  description = "The DNS name of the load balancer"
  value       = module.alb_waf_example.lb_dns_name
}