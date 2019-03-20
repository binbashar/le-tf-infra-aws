#
# DNS
#
resource "aws_route53_record" "pritunl" {
  zone_id = "${data.terraform_remote_state.vpc.aws_internal_zone_id[0]}"
  name    = "${var.instance_dns_record_name_1}"
  type    = "A"
  ttl     = "300"
  records = ["${aws_instance.openvpn_instance.private_ip}"]
}

resource "aws_route53_record" "webhooks" {
  zone_id = "${data.terraform_remote_state.vpc.aws_internal_zone_id[0]}"
  name    = "${var.instance_dns_record_name_2}"
  type    = "A"
  ttl     = "300"
  records = ["${aws_instance.openvpn_instance.public_ip}"]
}