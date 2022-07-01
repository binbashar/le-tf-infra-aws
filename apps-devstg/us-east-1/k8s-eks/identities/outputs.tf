output "cluster_autoscaler_role_arn" {
  description = "Cluster Autoscaler Role ARN"
  value       = module.role_cluster_autoscaler.iam_role_arn
}

output "certmanager_role_arn" {
  description = "CertManager Role ARN"
  value       = module.role_certmanager.iam_role_arn
}

output "private_externaldns_role_arn" {
  description = "ExternalDNS (Private) Role ARN"
  value       = module.role_externaldns_private.iam_role_arn
}

output "public_externaldns_role_arn" {
  description = "ExternalDNS (Public) Role ARN"
  value       = module.role_externaldns_public.iam_role_arn
}

output "aws_lb_controller_role_arn" {
  description = "AWS Load Balancer Controller Role ARN"
  value       = module.role_aws_lb_controller.iam_role_arn
}
