locals {
  # Removing apps- from domain
  environment   = replace(var.environment, "apps-", "")  
  tags = {
    Terraform   = "true"
    Environment = var.environment
  }
}
