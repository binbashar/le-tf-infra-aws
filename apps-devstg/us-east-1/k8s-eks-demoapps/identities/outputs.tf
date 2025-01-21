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

output "external_secrets_role_arn" {
  description = "External-secrets Role ARN"
  value       = module.role_external_secrets.iam_role_arn
}

output "grafana_role_arn" {
  description = "Grafana Role ARN"
  value       = module.role_grafana.iam_role_arn
}

output "fluent_bit_role_arn" {
  description = "Fluent Bit Role ARN"
  value       = module.role_fluent_bit.iam_role_arn
}

output "argo_cd_image_updater_role_arn" {
  description = "Argo CD Image Updater Role ARN"
  value       = module.role_argo_cd_image_updater.iam_role_arn
}

output "eks_addons_vpc_cni" {
  description = "EKS Add-ons VPC CNI Role ARN"
  value       = module.role_eks_addons_vpc_cni.iam_role_arn
}

output "eks_addons_ebs_csi" {
  description = "EKS Add-ons EBS CSI Role ARN"
  value       = module.role_eks_addons_ebs_csi.iam_role_arn
}

output "eks_addons_efs_csi" {
  description = "EKS Add-ons EFS CSI Role ARN"
  value       = module.role_eks_addons_efs_csi.iam_role_arn
}
