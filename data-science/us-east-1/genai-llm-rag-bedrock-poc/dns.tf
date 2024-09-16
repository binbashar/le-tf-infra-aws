resource "aws_route53_record" "priv_app_aws_dily_cl" {
  provider = aws.shared-route53
  zone_id  = data.terraform_remote_state.shared-dns.outputs.public_zone_id
  name     = "b2chat-poc.binbash.co"
  type     = "A"

  alias {
    evaluate_target_health = false
    name                   = module.alb.dns_name
    zone_id                = module.alb.zone_id
  }
}