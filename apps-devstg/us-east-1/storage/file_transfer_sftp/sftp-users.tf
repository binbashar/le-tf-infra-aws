# -----------------------------------------------------------------------------
# sFTP User Specs: TODO (NEEDS UPDATE)

# -----------------------------------------------------------------------------
module "sftp_customer_user" {
  source   = "github.com/binbashar/terraform-aws-sftp-user.git?ref=v1.0.0"
  for_each = var.customers

  sftp_server_id  = module.customer_sftp.sftp_server_id

  ssh_public_keys = [each.value["ssh_public_key"]]
  
  # aws_transfer_user
  user_name                 = each.value["username"]
  role_name                 = "${each.value["username"]}-sftp-role"
  home_directory_bucket     = {
    id = data.terraform_remote_state.apps-devstg-storage-s3-bucket.outputs.customers_buckets[each.value["username"]],
    arn = data.terraform_remote_state.apps-devstg-storage-s3-bucket.outputs.customers_buckets_arn[each.value["username"]]
  }

  home_directory_key_prefix = ""
  allowed_actions = [
    "s3:GetObject",
    "s3:GetObjectACL",
    "s3:PutObject",
    "s3:PutObjectACL",
  ]
  tags = {
    Customer = each.value["username"]
  }
}