resource "aws_iam_saml_provider" "client_vpn" {
  name                   = "${var.project}-client-vpn"
  saml_metadata_document = file("saml-metadata.xml")
}

module "vpn_sso_sg" {
  source = "github.com/binbashar/terraform-aws-security-group?ref=v5.1.2"

  name        = "vpn-sso-sg"
  description = "Security group for Client VPN endpoint"
  vpc_id      = local.vpc_id

  egress_with_cidr_blocks = [
    {
      rule        = "all-all"
      cidr_blocks = "0.0.0.0/0"
    }
  ]
}

resource "aws_ec2_client_vpn_endpoint" "sso" {
  description            = local.vpn_name
  vpc_id                 = local.vpc_id
  server_certificate_arn = data.terraform_remote_state.certs.outputs.certificate_arn
  client_cidr_block      = local.cidr
  split_tunnel           = local.split_tunnel
  dns_servers            = local.dns_servers  
  security_group_ids     = [module.vpn_sso_sg.security_group_id]

  authentication_options {
    type              = "federated-authentication"
    saml_provider_arn = aws_iam_saml_provider.client_vpn.arn
  }

  connection_log_options {
    enabled               = true
    cloudwatch_log_group  = aws_cloudwatch_log_group.sso.name
  }
}

resource "aws_cloudwatch_log_group" "sso" {
  name = "${var.project}-client-vpn"

  retention_in_days = 60
  kms_key_id        = data.terraform_remote_state.keys.outputs.aws_kms_key_arn
}

resource "aws_ec2_client_vpn_network_association" "this_sso" {
  for_each               =  toset(local.subnet_ids)

  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.sso.id
  subnet_id              = each.key
}

resource "aws_ec2_client_vpn_authorization_rule" "sso_devops" {
  for_each = toset(local.authorization_devops)

  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.sso.id
  target_network_cidr    = each.key
  access_group_id        = local.sso_group_devops
  description            = "Authorization for devops to ${each.key}"
}

resource "aws_ec2_client_vpn_route" "vpn_routes" {
  for_each = local.vpn_routes

  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.sso.id
  destination_cidr_block = each.value.destination_cidr_block
  target_vpc_subnet_id   = each.value.target_vpc_subnet_id
}
