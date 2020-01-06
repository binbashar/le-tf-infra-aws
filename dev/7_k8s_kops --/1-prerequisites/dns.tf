#
# Private Hosted Zone for this k8s cluster
#
resource "aws_route53_zone" "cluster_domain" {
    name = local.k8s_cluster_name
    vpc {
        vpc_id  = data.terraform_remote_state.vpc.outputs.vpc_id
    }
    
    # Had to add this ignore override because of the cross-vpc resolution
    # between devstg and shared
    lifecycle {
        ignore_changes = [
            vpc,
        ]
    }
}

#
# Associate Private Hosted Zone on DevStg with Shared VPC (Requester)
#
resource "null_resource" "create_remote_zone_auth" {
    provisioner "local-exec" {
        command = "aws route53 create-vpc-association-authorization --profile ${var.profile} --hosted-zone-id ${aws_route53_zone.cluster_domain.zone_id} --vpc VPCRegion=${var.region},VPCId=${data.terraform_remote_state.shared_vpc.outputs.vpc_id}"
    }
}