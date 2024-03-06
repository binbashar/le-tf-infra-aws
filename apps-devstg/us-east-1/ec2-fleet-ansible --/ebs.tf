resource "aws_volume_attachment" "this" {
  for_each = local.ebs_volumes

  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.this[each.key].id
  instance_id = module.ec2_ansible_fleet[each.key].id
}

resource "aws_ebs_volume" "this" {
  for_each = local.ebs_volumes

  availability_zone = module.ec2_ansible_fleet[each.key].availability_zone
  size              = lookup(each.value, "size", 1)
  type              = lookup(each.value, "type", "gp3")

  tags = local.tags
}
