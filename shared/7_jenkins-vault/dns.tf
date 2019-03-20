#
# DNS
#
resource "aws_route53_record" "jenkins" {
  zone_id = "${data.terraform_remote_state.vpc.aws_internal_zone_id[0]}"
  name    = "${var.instance_dns_record_name_1}"
  type    = "A"
  ttl     = "300"
  records = ["${aws_instance.jenkins-vault_instance.private_ip}"]
}

resource "aws_route53_record" "vault" {
  zone_id = "${data.terraform_remote_state.vpc.aws_internal_zone_id[0]}"
  name    = "${var.instance_dns_record_name_2}"
  type    = "A"
  ttl     = "300"
  records = ["${aws_instance.jenkins-vault_instance.private_ip}"]
}