#
# users.tf sensitive data output (alphabetically ordered)
#
# Machine / Automation Users
#
output "usernames" {
  description = "Map of user names by key"
  value = {
    for k, v in module.user : k => v.iam_user_name
  }
}

output "iam_access_key_ids" {
  description = "Map of IAM access key IDs by key"
  value = {
    for k, v in module.user : k => v.iam_access_key_id
  }
  sensitive = true
}

output "iam_access_key_encrypted_secrets" {
  description = "Map of encrypted access key secrets by key"
  value = {
    for k, v in module.user : k => v.iam_access_key_encrypted_secret
  }
  sensitive = true
}
