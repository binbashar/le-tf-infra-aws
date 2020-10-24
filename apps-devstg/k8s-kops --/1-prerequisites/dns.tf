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

  ## IMPORTANT!!! ##
  # Needs to be uncommented after the -> resource "null_resource" "create_remote_zone_auth"
  # is established
  vpc {
    vpc_id     = data.terraform_remote_state.vpc-shared.outputs.vpc_id
    vpc_region = var.region
  }
}

#
# DNS/VPC association between Shared VPC and cluster-kops-1.k8s.devstg.binbash.aws
#

# Authorize association from the owner account of the Private Zone
resource "aws_route53_vpc_association_authorization" "with_shared_vpc" {
  vpc_id  = data.terraform_remote_state.vpc-shared.outputs.vpc_id
  zone_id = aws_route53_zone.cluster_domain.zone_id
}


# Complete the association from the owner account of the VPC
resource "aws_route53_zone_association" "with_shared_vpc" {
  provider = aws.shared

  vpc_id  = aws_route53_vpc_association_authorization.with_shared_vpc.vpc_id
  zone_id = aws_route53_vpc_association_authorization.with_shared_vpc.zone_id
}
