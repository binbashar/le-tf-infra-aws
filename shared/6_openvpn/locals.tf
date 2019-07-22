locals {
  tags = {
    Name        = "infra-openvpn"
    Terraform   = "true"
    Environment = "${var.environment}"
  }
}