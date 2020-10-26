locals {
  bucket_name         = "${var.project}-${var.environment}-demo-files"
  bucket_name_replica = "${var.project}-${var.environment}-demo-files-replica"

  clients_statement = [
    {
      user   = data.terraform_remote_state.security-identities.outputs.user_s3_demo_name
      folder = "demo"
    },
  ]

  tags = {
    Terraform   = "true"
    Environment = var.environment
  }
}
