#
# DNS
#

#
# Private Hosted Zones
#
resource "aws_route53_zone" "aws_private_hosted_zone_1" {
  name = var.aws_private_hosted_zone_fqdn_1

  vpc {
    vpc_id     = data.terraform_remote_state.vpc-shared.outputs.vpc_id
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
    vpc_id     = data.terraform_remote_state.vpc-apps-devstg-eks.outputs.vpc_id
    vpc_region = var.region
  }
  vpc {
    vpc_id     = data.terraform_remote_state.vpc-apps-devstg-eks-demoapps.outputs.vpc_id
    vpc_region = var.region
  }
  vpc {
    vpc_id     = data.terraform_remote_state.vpc-apps-devstg.outputs.vpc_id
    vpc_region = var.region
  }
  vpc {
    vpc_id     = data.terraform_remote_state.vpc-apps-prd.outputs.vpc_id
    vpc_region = var.region
  }
  vpc {
    vpc_id     = data.terraform_remote_state.vpc-apps-prd-eks.outputs.vpc_id
    vpc_region = var.region
  }
  vpc {
    vpc_id     = data.terraform_remote_state.vpc-apps-devstg-eks-dr.outputs.vpc_id
    vpc_region = var.region
  }

  tags = local.tags
}

/*
#
# Subdomains: dev tools/envs entry points
#
resource "aws_route53_record" "dev_aws_bb" {
  zone_id = aws_route53_zone.aws.id
  name    = "dev.aws.binbash.com.ar"
  type    = "A"

  alias {
    name                   = local.dev_k8s_ingress_alb_id
    zone_id                = local.dev_k8s_ingress_alb_zone
    evaluate_target_health = true
  }
}
*/

#
# Create a TXT record to take ownership of the global sockshop domain
#
# resource "aws_route53_record" "sockshop_externaldns" {
#   zone_id = aws_route53_zone.aws_private_hosted_zone_1.zone_id
#   name    = "sockshopapp.devstg.aws.binbash.com.ar"
#   type    = "TXT"
#   records = [
#     "heritage=external-dns,external-dns/owner=binbash,external-dns/resource=ingress/argocd/argocd-server"
#   ]
#   ttl = 60
# }

#
# Create 2 records configured with a weighted policy so they balance
# traffic to each region
#
# resource "aws_route53_record" "sockshop_primary" {
#   zone_id = aws_route53_zone.aws_private_hosted_zone_1.zone_id
#   name    = "sockshopapp.devstg.aws.binbash.com.ar"
#   type    = "A"

#   set_identifier = "us-east-1"

#   alias {
#     name                   = "**********-**********.elb.us-east-1.amazonaws.com"
#     zone_id                = "Z26R**********"
#     evaluate_target_health = true
#   }

#   weighted_routing_policy {
#     weight = 127
#   }
# }

# resource "aws_route53_record" "sockshop_secondary" {
#   zone_id = aws_route53_zone.aws_private_hosted_zone_1.zone_id
#   name    = "sockshopapp.devstg.aws.binbash.com.ar"
#   type    = "A"

#   set_identifier = "us-east-2"

#   alias {
#     name                   = "**********-**********.elb.us-east-2.amazonaws.com"
#     zone_id                = "ZLMO**********"
#     evaluate_target_health = true
#   }

#   weighted_routing_policy {
#     weight = 127
#   }
# }
