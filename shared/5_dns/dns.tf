#
# DNS
#

#
# Public Hosted Zones
#
resource "aws_route53_zone" "aws_public_hosted_zone_1" {
  name = var.aws_public_hosted_zone_fqdn_1

  tags = local.tags
}

#
# MX records
#
resource "aws_route53_record" "aws_public_hosted_zone_1_mx_records" {
  zone_id = aws_route53_zone.aws_public_hosted_zone_1.id
  name    = var.aws_public_hosted_zone_fqdn_1
  type    = "MX"
  ttl     = 300

  records = [
    var.aws_public_hosted_zone_1_mail_servers_1,
    var.aws_public_hosted_zone_1_mail_servers_2,
    var.aws_public_hosted_zone_1_mail_servers_3,
    var.aws_public_hosted_zone_1_mail_servers_4,
    var.aws_public_hosted_zone_1_mail_servers_5,
  ]
}

#
# A records
#
resource "aws_route53_record" "aws_public_hosted_zone_1_A_record_1" {
  zone_id = aws_route53_zone.aws_public_hosted_zone_1.id
  name    = var.aws_public_hosted_zone_fqdn_1
  type    = "A"
  records = [var.aws_public_hosted_zone_1_address_record_1]
  ttl     = 300
}

resource "aws_route53_record" "aws_public_hosted_zone_1_A_record_2" {
  zone_id = aws_route53_zone.aws_public_hosted_zone_1.id
  name    = var.aws_public_hosted_zone_fqdn_record_name_1
  type    = "A"
  records = [var.aws_public_hosted_zone_1_address_record_1]
  ttl     = 300
}

resource "aws_route53_record" "aws_public_hosted_zone_1_A_record_3" {
  zone_id = aws_route53_zone.aws_public_hosted_zone_1.id
  name    = var.aws_public_hosted_zone_fqdn_record_name_2
  type    = "A"
  records = [var.aws_public_hosted_zone_1_address_record_2]
  ttl     = 300
}

#
# text records
#
resource "aws_route53_record" "aws_public_hosted_zone_1_TXT_record_1" {
  zone_id = aws_route53_zone.aws_public_hosted_zone_1.id
  name    = var.aws_public_hosted_zone_fqdn_1
  type    = "TXT"
  records = [var.aws_public_hosted_zone_1_text_record_1]
  ttl     = 300
}

resource "aws_route53_record" "aws_public_hosted_zone_1_TXT_record_2" {
  zone_id = aws_route53_zone.aws_public_hosted_zone_1.id
  name    = var.aws_public_hosted_zone_1_text_record_2_name
  type    = "TXT"
  records = [var.aws_public_hosted_zone_1_text_record_2]
  ttl     = 300
}

resource "aws_route53_record" "aws_public_hosted_zone_1_TXT_record_3" {
  zone_id = aws_route53_zone.aws_public_hosted_zone_1.id
  name    = var.aws_public_hosted_zone_1_text_record_3_name
  type    = "TXT"
  records = [var.aws_public_hosted_zone_1_text_record_3]
  ttl     = 300
}

resource "aws_route53_record" "aws_public_hosted_zone_1_TXT_record_4" {
  zone_id = aws_route53_zone.aws_public_hosted_zone_1.id
  name    = var.aws_public_hosted_zone_1_text_record_4_name
  type    = "TXT"
  records = [var.aws_public_hosted_zone_1_text_record_4]
  ttl     = 300
}

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
    vpc_id     = data.terraform_remote_state.vpc-apps-devstg.outputs.vpc_id
    vpc_region = var.region
  }
  vpc {
    vpc_id     = data.terraform_remote_state.vpc-apps-prd.outputs.vpc_id
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

#
# Certificate DNS validation entries
#
resource "aws_route53_record" "r53_dev_aws_bb" {
  name = "_XXXXXXXXXXXXXXXXXXXXXXXXXXXX.dev.aws.binbash.com.ar."
  type = "CNAME"
  zone_id = aws_route53_zone.aws.id
  records = ["_XXXXXXXXXXXXXXXXXXXXXXXXXXXX.XXXXXXXXXX.acm-validations.aws."]
  ttl = 60
}
*/

