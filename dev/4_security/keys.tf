resource "aws_key_pair" "compute-ssh-key" {
  key_name   = var.compute_ssh_key_name
  public_key = var.compute_ssh_public_key
}
