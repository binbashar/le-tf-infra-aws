# Manages AWS Config Aggregate Authorization
resource "aws_config_aggregate_authorization" "config_aggregate_auth" {
  account_id = var.security_account_id
  region     = var.region
}
