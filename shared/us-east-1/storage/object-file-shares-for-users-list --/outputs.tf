output "user_buckets" {
  description = "users' buckets"

  value = {
    for k, mod in module.user_buckets : k => mod.s3_bucket_id
  }
}

output "user_buckets_arn" {
  description = "users' buckets ARN"

  value = {
    for k, mod in module.user_buckets : k => mod.s3_bucket_arn
  }
}

output "user_roles" {
  description = "users' roles"

  value = {
    for k, mod in module.user_roles : k => mod.iam_role_arn
  }
}

output "bucket_usernames" {
  description = "users' usernames"

  value = {
    for k, mod in module.user_accounts : k => mod.iam_user_name
  }
}

#
# IMPORTANT: these are not encrypted by the module and will be exposed.
#
output "bucket_user_iam_access_key_ids" {
  description = "bucket_users' IAM Access Key IDs"

  value = {
    for k, mod in module.user_accounts : k => mod.iam_access_key_id
  }
}

#
# IMPORTANT: these will be encrypted with the GPG key given to the module.
#
output "bucket_user_iam_access_key_encrypted_secrets" {
  description = "bucket_users' IAM Access Key Secrets"

  value = {
    for k, mod in module.user_accounts : k => mod.iam_access_key_encrypted_secret
  }
}
