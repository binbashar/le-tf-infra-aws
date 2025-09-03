#================================#
# Terraform Backend Modules      #
#================================#

# Security Account Backend
module "base_tf_backend" {
  for_each = local.accounts_resources
  providers = {
    aws.primary   = aws.accounts["${each.key}-${each.value.region_primary}"]
    aws.secondary = aws.accounts["${each.key}-${each.value.region_secondary}"]
  }

  source   = "github.com/binbashar/terraform-aws-tfstate-backend.git?ref=v1.0.28"

  delimiter = each.value.inputs.bucket.delimiter
  namespace = each.value.inputs.bucket.namespace
  stage     = each.key
  name      = "terraform-backend"

  acl                           = each.value.inputs.security.acl
  block_public_acls             = each.value.inputs.security.block_public_acls
  block_public_policy           = each.value.inputs.security.block_public_policy
  restrict_public_buckets       = each.value.inputs.security.restrict_public_buckets
  enable_server_side_encryption = each.value.inputs.security.enable_server_side_encryption
  enforce_ssl_requests          = each.value.inputs.security.enforce_ssl_requests
  ignore_public_acls            = each.value.inputs.security.ignore_public_acls

  bucket_replication_enabled    = each.value.inputs.replication.bucket_replication_enabled
  notifications_sns             = each.value.inputs.replication.notifications_sns
  bucket_lifecycle_enabled      = each.value.inputs.replication.bucket_lifecycle_enabled
  billing_mode                  = each.value.inputs.replication.billing_mode
  enable_point_in_time_recovery = each.value.inputs.replication.enable_point_in_time_recovery
  create_kms_key                = each.value.inputs.replication.create_kms_key

  tags = merge(each.value.inputs.tags, {
    Account     = each.key
    AccountID   = tostring(each.value.id)
  })
}
