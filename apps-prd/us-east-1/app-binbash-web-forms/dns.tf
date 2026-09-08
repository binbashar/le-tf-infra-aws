#
# Custom domain. The certificate is created and validated by the security-certs
# layer — apply that first or this fails with a certificate-not-found error.
#
resource "aws_apigatewayv2_domain_name" "forms" {
  domain_name = local.forms_fqdn
  tags        = local.tags

  domain_name_configuration {
    certificate_arn = data.terraform_remote_state.certificates.outputs.forms_binbash_co_certificate_arn
    endpoint_type   = "REGIONAL"
    security_policy = "TLS_1_2"
  }
}

resource "aws_apigatewayv2_api_mapping" "forms" {
  api_id      = aws_apigatewayv2_api.forms.id
  domain_name = aws_apigatewayv2_domain_name.forms.id
  stage       = aws_apigatewayv2_stage.default.id
}

#
# The alias record. The zone is in the shared account, hence aws.shared-route53 —
# the same provider alias app-binbash-web uses for the same zone.
#
resource "aws_route53_record" "forms" {
  provider = aws.shared-route53
  zone_id  = data.terraform_remote_state.dns-binbash-co.outputs.public_zone_id
  name     = local.forms_fqdn
  type     = "A"

  alias {
    evaluate_target_health = false
    name                   = aws_apigatewayv2_domain_name.forms.domain_name_configuration[0].target_domain_name
    zone_id                = aws_apigatewayv2_domain_name.forms.domain_name_configuration[0].hosted_zone_id
  }
}
