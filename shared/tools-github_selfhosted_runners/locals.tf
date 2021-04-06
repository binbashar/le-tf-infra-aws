locals {
  tags = {
    Name        = "infra-github-selfhosted-runners"
    Terraform   = "true"
    Environment = var.environment
  }
}
