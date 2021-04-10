#
# EKS Module
#
output "cluster_id" {
  description = "EKS Cluster ID"
  value       = module.eks.cluster_id
}

output "cluster_name" {
  description = "EKS Cluster Name"
  value       = data.terraform_remote_state.shared-eks-vpc.outputs.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane."
  value       = module.eks.cluster_endpoint
}

output "cluster_oidc_issuer_url" {
  description = "EKS OpenID Connect Issuer URL."
  value       = module.eks.cluster_oidc_issuer_url
}

output "cluster_security_group_id" {
  description = "Security group ids attached to the cluster control plane."
  value       = module.eks.cluster_security_group_id
}

# output "kubectl_config" {
#   description = "kubectl config as generated by the module."
#   value       = module.eks.kubeconfig
# }

# output "config_map_aws_auth" {
#   description = "A kubernetes configuration to authenticate to this EKS cluster."
#   value       = module.eks.config_map_aws_auth
# }

output "region" {
  description = "AWS region."
  value       = var.region
}
