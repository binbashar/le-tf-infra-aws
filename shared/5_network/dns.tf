#
# Domains
#
resource "aws_route53_zone" "aws" {
  name = "aws.binbash.com.ar"
  tags = "${local.tags}"
}

/*resource "aws_route53_record" "live-ns" {
  zone_id = "${aws_route53_zone.aws.id}"
  name    = "binbash.com.ar"
  type    = "NS"
  ttl     = "30"

  records = [
      "ns-1447.awsdns-52.org."
      "ns-157.awsdns-19.com."
      "ns-1978.awsdns-55.co.uk."
      "ns-959.awsdns-55.net."
  ]
}


#
# Subdomains: dev tools/envs entry points
#
resource "aws_route53_record" "dev_aws_bb" {
  zone_id = "${aws_route53_zone.aws.id}"
  name    = "dev.aws.binbash.com.ar"
  type    = "A"

  alias {
    name                   = "${local.dev_k8s_ingress_alb_id}"
    zone_id                = "${local.dev_k8s_ingress_alb_zone}"
    evaluate_target_health = true
  }
}

#
# Certificate DNS validation entries
#
resource "aws_route53_record" "r53_dev_aws_bb" {
  name = "_XXXXXXXXXXXXXXXXXXXXXXXXXXXX.dev.aws.binbash.com.ar."
  type = "CNAME"
  zone_id = "${aws_route53_zone.aws.id}"
  records = ["_XXXXXXXXXXXXXXXXXXXXXXXXXXXX.XXXXXXXXXX.acm-validations.aws."]
  ttl = 60
}
*/
