locals {
  lambda_function_name = "MonthlyServicesUsage"

  # Convert account IDs to strings to preserve leading zeros (e.g., 094271238832)
  # Without this, JSON encoding treats IDs as numbers and strips leading zeros
  accounts_with_string_ids = {
    for account_name, account_data in var.accounts : account_name => {
      id    = format("%012d", account_data.id)
      email = account_data.email
    }
  }

  tags = {
    Terraform   = "true"
    Environment = var.environment
    Layer       = local.layer_name
  }
}
