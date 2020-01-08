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
output "cluster_name" {
    description = "The name of this cluster"
    value       = local.k8s_cluster_name
}
output "cluster_version" {
    description = "Kubernetes version"
    value       = local.k8s_cluster_version
}
output "cluster_master_azs" {
    description = "Availability Zones where masters will be deployed"
    value       = [ data.terraform_remote_state.vpc.outputs.availability_zones[0] ]
}
output "cluster_api_elb_extra_security_group" {
    value = ""
}
output "node_cloud_labels" {
    description = "Cloud labels will become tags on the nodes"
    value       = local.node_cloud_labels
}

#
# Kops Resources
#
output "kops_s3_bucket" {
    description = "Kops State S3 Bucket"
    value = aws_s3_bucket.kops_state.bucket
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
        data.terraform_remote_state.vpc.outputs.availability_zones, list(
            data.terraform_remote_state.vpc.outputs.nat_gateway_ids[0],
            data.terraform_remote_state.vpc.outputs.nat_gateway_ids[0],
            data.terraform_remote_state.vpc.outputs.nat_gateway_ids[0]
        )
    )
}
output "shared_vpc_cidr_block" {
    value = data.terraform_remote_state.shared_vpc.outputs.vpc_cidr_block
}