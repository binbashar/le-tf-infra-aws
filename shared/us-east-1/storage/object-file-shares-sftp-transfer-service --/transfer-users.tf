#
# Create user accounts for each customer
#
module "sftp_user" {
  source = "github.com/binbashar/terraform-aws-sftp-user.git?ref=v2.0.0"

  for_each = var.users

  sftp_server_id  = module.sftp_server.sftp_server_id
  ssh_public_keys = [each.value["ssh_public_key"]]
  user_name       = each.value["username"]
  role_name       = "${var.prefix}-sftp-${each.value["username"]}"

  home_directory_bucket = {
    id  = module.s3_bucket.s3_bucket_id,
    arn = module.s3_bucket.s3_bucket_arn
  }
  home_directory_key_prefix = ""

  allowed_actions = [
    "s3:GetObject",
    "s3:GetObjectACL",
    "s3:GetObjectVersion",
    "s3:PutObject",
    "s3:PutObjectACL",
    "s3:PutObjectVersion",
    "s3:DeleteObject",
  ]

  tags = {
    Customer = each.value["username"]
  }
}
