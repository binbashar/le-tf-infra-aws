locals {
  tags = {
    Name        = "infra-jenkinsvault"
    Terraform   = "true"
    Environment = "${var.environment}"
  }
}