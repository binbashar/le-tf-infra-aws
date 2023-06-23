#
# Public Hosted Zones
#
resource "aws_route53_zone" "public" {
  name = var.public_hosted_zone_fqdn
  tags = local.tags
}

#
# Redirect leverage.binbash.com.ar to leverage.binbash.co
#
module "domain-redirect-binbash_com_ar-to-binbash_co" {
  source                  = "github.com/binbashar/terraform-aws-domain-redirect?ref=v1.0.0"
  source_hosted_zone_name = "leverage.binbash.com.ar"
  target_url              = "leverage.binbash.co"
  providers               = {
    aws.us-east-1 = aws.main_region
  }
}

#
# CNAME records
#
/*resource "aws_route53_record" "pub_CNAME_leverage_binbash_com_ar" {
  zone_id = aws_route53_zone.public.id
  name    = "leverage.binbash.com.ar"
  records = ["binbashar.github.io"]
  type    = "CNAME"
  ttl     = 300
}*/
