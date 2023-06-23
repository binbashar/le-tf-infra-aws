#
# DNS
#

#
# Private Hosted Zones
#
resource "aws_route53_zone" "private" {
  name = var.private_hosted_zone_fqdn

  vpc {
    vpc_id     = data.terraform_remote_state.vpc-shared.outputs.vpc_id
    vpc_region = var.region
  }

  #
  # This Remote Account VPCs starting at line #29 are added as a post step after
  # the local-exec assoc occurs.
  # If you won't like to add them please consider the below workaround were you
  # have to add this ignore override because of the cross-vpc resolution
  # between shared and vpc-dev
  # between shared and vpc-dev-eks
  #
  #lifecycle {
  #      ignore_changes = [
  #          vpc,
  #      ]
  #  }

  #
  # Cross-account VPC Associations
  #
  /*vpc {
    vpc_id     = data.terraform_remote_state.vpc-apps-devstg.outputs.vpc_id
    vpc_region = var.region
  }
  vpc {
    vpc_id     = data.terraform_remote_state.vpc-apps-devstg-eks.outputs.vpc_id
    vpc_region = var.region
  }
  vpc {
    vpc_id     = data.terraform_remote_state.dns-apps-devstg-eks-v117.outputs.vpc_id
    vpc_region = var.region
  }
  vpc {
    vpc_id     = data.terraform_remote_state.vpc-apps-devstg-eks-demoapps.outputs.vpc_id
    vpc_region = var.region
  }
  vpc {
    vpc_id     = data.terraform_remote_state.vpc-apps-devstg-eks-dr.outputs.vpc_id
    vpc_region = var.region
  }
  vpc {
    vpc_id     = data.terraform_remote_state.vpc-apps-prd.outputs.vpc_id
    vpc_region = var.region
  }*/

  tags = local.tags
}
