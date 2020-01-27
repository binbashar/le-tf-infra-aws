#
# Cluster Settings
#
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
  value = [
    tostring(data.terraform_remote_state.vpc.outputs.availability_zones[0][0]),
    tostring(data.terraform_remote_state.vpc.outputs.availability_zones[0][1]),
    tostring(data.terraform_remote_state.vpc.outputs.availability_zones[0][2])
  ]
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
output "hosted_zone_id" {
  description = "Hosted Zone ID (Kops requires a domain for the cluster)"
  value       = aws_route53_zone.cluster_domain.zone_id
}
output "vpc_id" {
  value = data.terraform_remote_state.vpc.outputs.vpc_id
}
output "vpc_cidr_block" {
  value = data.terraform_remote_state.vpc.outputs.vpc_cidr_block
}
output "availability_zones" {
  value = [
    tostring(data.terraform_remote_state.vpc.outputs.availability_zones[0][0]),
    tostring(data.terraform_remote_state.vpc.outputs.availability_zones[0][1]),
    tostring(data.terraform_remote_state.vpc.outputs.availability_zones[0][2])
  ]
}

# Consider index [0][3]...[0][N] in case you have 4 or more AZs / Subnets
#
output "public_subnet_ids" {
  value = zipmap(
    tolist([
      data.terraform_remote_state.vpc.outputs.availability_zones[0][0],
      data.terraform_remote_state.vpc.outputs.availability_zones[0][1],
      data.terraform_remote_state.vpc.outputs.availability_zones[0][2]
    ]),
    tolist([
      data.terraform_remote_state.vpc.outputs.public_subnets[0][0],
      data.terraform_remote_state.vpc.outputs.public_subnets[0][1],
      data.terraform_remote_state.vpc.outputs.public_subnets[0][2
    ]])
  )
}
output "private_subnet_ids" {
  value = zipmap(
    tolist([
      data.terraform_remote_state.vpc.outputs.availability_zones[0][0],
      data.terraform_remote_state.vpc.outputs.availability_zones[0][1],
      data.terraform_remote_state.vpc.outputs.availability_zones[0][2]
    ]),
    tolist([
      data.terraform_remote_state.vpc.outputs.private_subnets[0][0],
      data.terraform_remote_state.vpc.outputs.private_subnets[0][1],
      data.terraform_remote_state.vpc.outputs.private_subnets[0][2]
    ])
  )
}
output "nat_gateway_ids" {
  value = zipmap(
    tolist([
      data.terraform_remote_state.vpc.outputs.availability_zones[0][0],
      data.terraform_remote_state.vpc.outputs.availability_zones[0][1],
      data.terraform_remote_state.vpc.outputs.availability_zones[0][2]
    ]),
    tolist([
      data.terraform_remote_state.vpc.outputs.nat_gateway_ids[0][0],
      data.terraform_remote_state.vpc.outputs.nat_gateway_ids[0][0],
      data.terraform_remote_state.vpc.outputs.nat_gateway_ids[0][0]
    ])
  )
}
output "shared_vpc_cidr_block" {
  value = data.terraform_remote_state.vpc_shared.outputs.vpc_cidr_block
}
