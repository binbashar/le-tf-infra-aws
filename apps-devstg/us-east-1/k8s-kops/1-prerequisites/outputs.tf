#
# Cluster Settings
#
output "project_short" {
  description = "Project Short Name"
  value       = var.project
}
output "profile" {
  description = "AWS Profile"
  value       = var.profile
}
output "region" {
  description = "AWS Region"
  value       = var.region
}
output "environment" {
  description = "AWS Region"
  value       = var.environment
}
output "cluster_name" {
  description = "The name of this cluster"
  value       = local.k8s_cluster_name
}
output "cluster_version" {
  description = "Kubernetes version"
  value       = local.k8s_cluster_version
}
output "etcd_clusters_version" {
  description = "etcd version"
  value       = local.etcd_clusters_version
}
output "networking_calico_major_version" {
  description = "Calico network CNI major version"
  value       = local.networking_calico_major_version
}

#
# Cluster Master Instance Group (IG)
#
output "cluster_master_azs" {
  description = "Availability Zones where masters will be deployed"
  value       = local.cluster_master_azs
}
output "cluster_api_elb_extra_security_group" {
  value = ""
}
output "kops_master_machine_type" {
  description = "K8s Kops Master Nodes Machine (EC2) type and size"
  value       = local.kops_master_machine_type
}
output "kops_master_machine_max_size" {
  description = "K8s Kops Master Nodes ASG max size"
  value       = local.kops_master_machine_max_size
}
output "kops_master_machine_min_size" {
  description = "K8s Kops Master Nodes ASG min size"
  value       = local.kops_master_machine_min_size
}

#
# Cluster Worker Nodes Instance Group (IG)
#
output "node_cloud_labels" {
  description = "Cloud labels will become tags on the nodes"
  value       = local.node_cloud_labels
}
output "kops_worker_machine_type" {
  description = "K8s Kops Worker Nodes Machine (EC2) type and size"
  value       = local.kops_worker_machine_type
}
output "kops_worker_machine_max_size" {
  description = "K8s Kops Worker Nodes ASG max size"
  value       = local.kops_worker_machine_max_size
}
output "kops_worker_machine_min_size" {
  description = "K8s Kops Worker Nodes ASG min size"
  value       = local.kops_worker_machine_min_size
}

#
# Kops Resources
#
output "kops_s3_bucket" {
  description = "Kops State S3 Bucket"
  value       = aws_s3_bucket.kops_state.bucket
}
output "kops_ami_id" {
  description = "Kops AMI ID"
  value       = local.kops_ami_id
}

#
# Network Resources
#
output "gossip_cluster" {
  description = "Wheter is a gossip cluster"
  value       = local.gossip_cluster
}
output "hosted_zone_id" {
  description = "Hosted Zone ID (Kops requires a domain for the cluster)"
  value       = local.gossip_cluster ? null : aws_route53_zone.cluster_domain[0].zone_id
}
output "vpc_id" {
  value = data.terraform_remote_state.vpc.outputs.vpc_id
}
output "vpc_cidr_block" {
  value = data.terraform_remote_state.vpc.outputs.vpc_cidr_block
}
output "availability_zones" {
  value = data.terraform_remote_state.vpc.outputs.availability_zones
}
output "public_subnet_ids" {
  value = zipmap(
    data.terraform_remote_state.vpc.outputs.availability_zones,
    data.terraform_remote_state.vpc.outputs.public_subnets
  )
}
output "private_subnet_ids" {
  value = zipmap(
    data.terraform_remote_state.vpc.outputs.availability_zones,
    data.terraform_remote_state.vpc.outputs.private_subnets
  )
}
output "nat_gateway_ids" {
  value = zipmap(
    data.terraform_remote_state.vpc.outputs.availability_zones, [for az in data.terraform_remote_state.vpc.outputs.availability_zones : data.terraform_remote_state.vpc.outputs.nat_gateway_ids[0]]
  )
}
output "shared_vpc_cidr_block" {
  value = data.terraform_remote_state.vpc-shared.outputs.vpc_cidr_block
}
output "ssh_pub_key_path" {
  value = var.ssh_pub_key_path
}

output "devops_role" {
  value = tolist(data.aws_iam_roles.devopsrole.arns)[0]
}

#
# IRSA
#
output "irsa_enabled" {
  value = var.enable_irsa
}
output "irsa_bucket_name" {
  value = var.enable_irsa ? aws_s3_bucket.kops_irsa[0].id : ""
}

#
# KARPENTER
#
output "karpenter_enabled" {
  value = var.enable_irsa && var.enable_karpenter
}

output "kops_worker_machine_types_karpenter" {
  description = "List of K8s Kops Worker Nodes Machine (EC2) types and size for Karpenter"
  value       = local.kops_worker_machine_types_karpenter
}
