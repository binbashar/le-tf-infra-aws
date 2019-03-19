#
# DNS
#
resource "aws_route53_record" "jenkins" {
  zone_id = "${data.terraform_remote_state.vpc.aws_internal_zone_id[0]}"
  name    = "jenkins.aws.binbash.com.ar"
  type    = "A"
  ttl     = "300"
  records = ["${aws_instance.jenkins-vault_instance.private_ip}"]
}

resource "aws_route53_record" "vault" {
  zone_id = "${data.terraform_remote_state.vpc.aws_internal_zone_id[0]}"
  name    = "vault.aws.binbash.com.ar"
  type    = "A"
  ttl     = "300"
  records = ["${aws_instance.jenkins-vault_instance.private_ip}"]
}

resource "aws_route53_record" "devsecops" {
  zone_id = "${data.terraform_remote_state.vpc.aws_internal_zone_id[0]}"
  name    = "devsecops.aws.binbash.com.ar"
  type    = "A"
  ttl     = "300"
  records = ["${aws_instance.jenkins-vault_instance.private_ip}"]
}