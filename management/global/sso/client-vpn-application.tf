data "aws_ssoadmin_instances" "this" {
  count = local.enable_sso_client_vpn == true ? 1 : 0
}

resource "aws_ssoadmin_application" "client_vpn" {
  count = local.enable_sso_client_vpn == true ? 1 : 0

  name                     = "${var.project}-client-vpn"
  application_provider_arn = "arn:aws:sso::aws:applicationProvider/custom-saml"
  description              = "Awsome Clieny VPN"
  instance_arn             = tolist(data.aws_ssoadmin_instances.this[0].arns)[0]

  portal_options {
    visibility = "ENABLED"

    sign_in_options {
      origin = "IDENTITY_CENTER"
    }
  }
}

resource "aws_ssoadmin_application_assignment" "client_vpn" {
  for_each = local.enable_sso_client_vpn == true ? toset(local.client_vpn_groups) : toset([])

  application_arn = aws_ssoadmin_application.client_vpn[0].application_arn
  principal_id    = split("/", aws_identitystore_group.default[each.key].id)[1]
  principal_type  = "GROUP"
}