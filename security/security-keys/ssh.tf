resource "aws_key_pair" "compute-ssh-key" {
  for_each = var.ssh_settings != null ? toset(var.regions) : toset([])
  provider = aws.by_region[each.key]
  key_name   = var.ssh_settings.key_name
  public_key = var.ssh_settings.public_key
}
