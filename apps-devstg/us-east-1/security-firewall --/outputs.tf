output "wafv2_regional_alb_arn" {
  description = "The ARN of the WAFv2 WebACL"
  value       = module.wafv2_regional_alb[0].web_acl_arn
}