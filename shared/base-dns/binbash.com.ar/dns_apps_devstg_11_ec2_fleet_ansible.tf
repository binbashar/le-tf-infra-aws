#
# DNS private hosted zone aws.binbash.com.ar records for apps-devstg/11_ec2_fleet_ansible instances
#

resource "aws_route53_record" "ansible_fleet" {
  // same number of records as instances
  count   = var.aws_private_hosted_zone_apps_devstg_ec2_fleet_ansible_created == true ? data.terraform_remote_state.ec2-fleet-ansible.outputs.instance_count : 0
  zone_id = aws_route53_zone.aws_private_hosted_zone_1.zone_id
  name    = "ansible_fleet_${count.index}.aws.binbash.com.ar"
  type    = "A"
  ttl     = "300"
  // matches up record N to instance N
  records = [element(data.terraform_remote_state.ec2-fleet-ansible.outputs.private_ip, count.index)]
}
