#
# Given that EC2 basic layout module has an issue with creating a DNS record for
# the instance in a private zone, we are creating such record here.
#
resource "aws_route53_record" "private_domain" {
  zone_id = data.terraform_remote_state.dns.outputs.aws_internal_zone_id[0]
  name    = "jenkins-master.aws.binbash.com.ar"
  type    = "A"
  records = [module.jenkins_master.aws_instance_private_ip]
  ttl     = "3600"
}