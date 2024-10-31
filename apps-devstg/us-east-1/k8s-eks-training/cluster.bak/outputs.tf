#
# EKS Module
#
output "cluster_id" {
  description = "EKS Cluster ID"
  value       = module.cluster.cluster_id
}

output "cluster_name" {
  description = "EKS Cluster Name"
  value       = data.terraform_remote_state.cluster-vpc.outputs.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane."
  value       = module.cluster.cluster_endpoint
}

output "cluster_version" {
  description = "Kubernetes version."
  value       = module.cluster.cluster_version
}

output "cluster_oidc_issuer_url" {
  description = "EKS OpenID Connect Issuer URL."
  value       = module.cluster.cluster_oidc_issuer_url
}

output "cluster_oidc_provider_arn" {
  description = "EKS OpenID Connect Provider ARN."
  value       = module.cluster.oidc_provider_arn
}

output "cluster_primary_security_group_id" {
  description = "Security group ids attached to the cluster control plane."
  value       = module.cluster.cluster_primary_security_group_id
}

output "cluster_kubeconfig_instructions" {
  description = "Instructions to generate a kubeconfig file."
  value       = <<CMD
=========================================================================
Run the following command to generate a kubeconfig file for this project:
=========================================================================
```
export AWS_CONFIG_FILE=~/.aws/${var.project}/config
export AWS_SHARED_CREDENTIALS_FILE=~/.aws/${var.project}/credentials
export KUBECONFIG=~/.kube/${var.project}/${var.environment}
aws eks update-kubeconfig --region ${var.region} --name ${data.terraform_remote_state.cluster-vpc.outputs.cluster_name} --profile ${var.profile}
```
CMD
}
