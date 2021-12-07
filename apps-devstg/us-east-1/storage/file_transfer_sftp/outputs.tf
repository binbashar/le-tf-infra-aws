/*output "customers_buckets" {
  description = "Customers' buckets"

  value = {
    for k, mod in module.customers_buckets : k => mod.s3_bucket_id
  }
}

output "customers_roles" {
  description = "Customers' roles"

  value = {
    for k, mod in module.customers_roles : k => mod.iam_role_arn
  }
}

output "customers_usernames" {
  description = "Customers' usernames"

  value = {
    for k, mod in module.customers_user_accounts : k => mod.iam_user_name
  }
}

#
# IMPORTANT: these are not encrypted by the module and will be exposed.
#
output "customers_iam_access_key_ids" {
  description = "Customers' IAM Access Key IDs"

  value = {
    for k, mod in module.customers_user_accounts : k => mod.iam_access_key_id
  }
}

#
# IMPORTANT: these will be encrypted with the GPG key given to the module.
#
output "customers_iam_access_key_encrypted_secrets" {
  description = "Customers' IAM Access Key Secrets"

  value = {
    for k, mod in module.customers_user_accounts : k => mod.iam_access_key_encrypted_secret
  }
}*/
