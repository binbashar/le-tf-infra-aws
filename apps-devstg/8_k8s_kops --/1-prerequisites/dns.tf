#
# Private Hosted Zone for this k8s cluster
#
resource "aws_route53_zone" "cluster_domain" {
  name = local.k8s_cluster_name

  vpc {
    vpc_id     = data.terraform_remote_state.vpc.outputs.vpc_id
    vpc_region = var.region
  }

  #
  # This Remote Account VPCs are added as a post step after the local-exec assoc occurs.
  # If you won't like to add them please consider the below workaround
  # Had to add this ignore override because of the cross-vpc resolution
  # between shared and vpc-dev
  # between shared and vpc-dev-eks
  #
  #lifecycle {
  #      ignore_changes = [
  #          vpc,
  #      ]
  #  }

  vpc {
    vpc_id     = data.terraform_remote_state.vpc_shared.outputs.vpc_id
    vpc_region = var.region
  }
}


# Reference Link: https://aws.amazon.com/premiumsupport/knowledge-center/private-hosted-zone-different-account/

#============================================================#
# HOSTED ZONE: aws.binbash.com.ar from Shared to Dev Account
#============================================================#
// eg:
//aws route53 list-hosted-zones --profile ${var.profile}
//aws route53 create-vpc-association-authorization  --hosted-zone-id Z2UPXXXXXXXXX --vpc VPCRegion=us-east-1,VPCId=vpc-6812de10 --profile 'profile-host-acct'
//aws route53 list-vpc-association-authorizations   --hosted-zone-id Z2UPXXXXXXXXX                                              --profile 'profile-host-acct'
//aws route53 associate-vpc-with-hosted-zone        --hosted-zone-id Z2UPXXXXXXXXX --vpc VPCRegion=us-east-1,VPCId=vpc-6812de10 --profile 'profile-remote-acct'
//aws route53 delete-vpc-association-authorization  --hosted-zone-id Z2UPXXXXXXXXX --vpc VPCRegion=us-east-1,VPCId=vpc-6812de10 --profile 'profile-host-acct'

#
# Request Association between Private Hosted Zone on DevStg (cluster-kops-1.k8s.dev.binbash.aws) with Shared VPC
#
resource "null_resource" "create_remote_zone_auth" {
  provisioner "local-exec" {
    command = "aws route53 create-vpc-association-authorization --profile ${var.profile} --hosted-zone-id ${aws_route53_zone.cluster_domain.zone_id} --vpc VPCRegion=${var.region},VPCId=${data.terraform_remote_state.vpc_shared.outputs.vpc_id}"
  }
}
