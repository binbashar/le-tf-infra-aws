region_secondary = "us-west-2"
region_primary   = "us-east-1"

backend_settings = {
  bucket = {
    key       = "baseline/base-tf-backend/terraform.tfstate"
    name      = "terraform-backend"
    delimiter = "-"
    namespace = "bb"
  }
  security = {
    acl                           = "private"
    block_public_acls             = true
    block_public_policy           = true
    restrict_public_buckets       = true
    enable_server_side_encryption = true
    enforce_ssl_requests          = true
    ignore_public_acls            = true
    force_destroy                 = false
  }
  replication = {
    bucket_replication_enabled    = true
    notifications_sns             = false
    bucket_lifecycle_enabled      = false
    billing_mode                  = "PROVISIONED"
    enable_point_in_time_recovery = false
    create_kms_key                = false
  }
  tags = {
    Layer = "baseline/base-tf-backend"
  }
}
