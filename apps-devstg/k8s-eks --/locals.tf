locals {
  tags = {
    Terraform   = "true"
    Environment = var.environment
    GithubRepo  = "terraform-aws-eks"
    GithubOrg   = "binbashar"
  }
}
