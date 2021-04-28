locals {
  domain_name = "es-aws-binbash"
  
  tags = {
    Name               = "${var.prefix}-${var.name}"
    Terraform          = "true"
    Environment        = var.environment
  }
}
