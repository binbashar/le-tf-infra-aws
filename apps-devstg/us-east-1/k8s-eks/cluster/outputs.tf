#
# EKS Module
#
output "cluster_id" {
  description = "EKS Cluster ID"
  value       = module.eks.cluster_id
}

output "cluster_name" {
  description = "EKS Cluster Name"
  value       = module.eks.cluster_name
}

output "cluster_version" {
  description = "EKS Cluster Version"
  value       = module.eks.cluster_version
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane."
  value       = module.eks.cluster_endpoint
}

output "cluster_oidc_issuer_url" {
  description = "EKS OpenID Connect Issuer URL."
  value       = module.eks.cluster_oidc_issuer_url
}

output "cluster_oidc_provider_arn" {
  description = "EKS OpenID Connect Provider ARN."
  value       = module.eks.cluster_oidc_provider_arn
}

output "cluster_primary_security_group_id" {
  description = "Security group ids attached to the cluster control plane."
  value       = module.eks.cluster_primary_security_group_id
}

output "cluster_kubeconfig_instructions" {
  description = "Instructions to generate a kubeconfig file."
  value       = module.eks.cluster_kubeconfig_instructions
}
output "cluster_iam_role_name" {
  description = ""
  value       = module.eks.cluster_iam_role_name
}
