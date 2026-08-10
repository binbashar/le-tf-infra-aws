#
# ALB Outputs
#
output "alb_dns_name" {
  description = "DNS name of the ALB"
  value       = module.apps_devstg_alb_ecs_demoapps.dns_name
}

output "alb_arn" {
  description = "ARN of the ALB"
  value       = module.apps_devstg_alb_ecs_demoapps.arn
}

output "alb_security_group_id" {
  description = "Security group ID of the ALB"
  value       = module.apps_devstg_alb_ecs_demoapps.security_group_id
}

output "alb_target_groups" {
  description = "Target groups created by the ALB module"
  value       = module.apps_devstg_alb_ecs_demoapps.target_groups
}

output "alb_listeners" {
  description = "Listeners created by the ALB module"
  value       = module.apps_devstg_alb_ecs_demoapps.listeners
}

output "alb_https_listener_arn" {
  description = "ARN of the HTTPS listener"
  value       = module.apps_devstg_alb_ecs_demoapps.listeners["https"].arn
}

output "target_groups" {
  description = "Target group configuration for API Gateway routing"
  value = {
    for target_name, target_config in local.target_groups :
    target_name => {
      arn      = module.apps_devstg_alb_ecs_demoapps.target_groups[target_name].arn
      dns_name = "${target_config.subdomain}.${local.base_domain}"
      port     = target_config.port
    }
  }
}

#
# ECS Cluster Outputs
#
output "ecs_cluster_id" {
  description = "ID of the ECS cluster"
  value       = module.apps_devstg_ecs_cluster.cluster_id
}

output "ecs_cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = module.apps_devstg_ecs_cluster.cluster_arn
}

output "ecs_services" {
  description = "ECS services created"
  value       = module.apps_devstg_ecs_cluster.services
  sensitive   = true
}
