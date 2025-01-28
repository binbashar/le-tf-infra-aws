data "aws_lb" "traefik" {
  count = var.traefik && var.create_route53_record ? 1 : 0

  tags = {
    "kubernetes.io/service-name" : "traefik/traefik"
  }

  depends_on = [resource.helm_release.traefik]
}

resource "aws_route53_record" "traefik-faina" {
  provider = aws.shared

  count = var.traefik && var.create_route53_record ? 1 : 0

  allow_overwrite = true
  name            = "subdomain.binbash.co"
  records         = [data.aws_lb.traefik[0].dns_name]
  ttl             = 3600
  type            = "CNAME"
  zone_id         = data.terraform_remote_state.shared-dns.outputs.public_zone_id

  depends_on = [data.aws_lb.traefik]
}

resource "aws_route53_record" "traefik-therecord" {
  provider = aws.shared

  count = var.traefik && var.create_route53_record ? 1 : 0

  allow_overwrite = true
  name            = "ca.therecord.binbash.co"
  records         = [data.aws_lb.traefik[0].dns_name]
  ttl             = 3600
  type            = "CNAME"
  zone_id         = data.terraform_remote_state.shared-dns.outputs.public_zone_id

  depends_on = [data.aws_lb.traefik]
}
