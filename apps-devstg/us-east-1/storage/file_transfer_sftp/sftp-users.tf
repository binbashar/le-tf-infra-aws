# -----------------------------------------------------------------------------
# sFTP User Specs: TODO (NEEDS UPDATE)
#  - Encrypted: Yes [HIPAA]
#  - Logging: Yes [HIPAA]
#  - Versioned: Yes [HIPAA]
#  - Enforce HTTPS: Yes [HIPAA]
#  - Private (ACL, Bucket Policy): Yes [HIPAA]
#  - Replicated: TBD -- For the sake of disaster recovery, still kind of easy to set up at a later time
#  - Storage Lifecycle: TBD -- For the sake of cost optimization; can be easily set up at any time but people tend to forget about it until costs reveal the mistake
#  - MFA Delete: TBD -- For the sake of data safety, but can be easily set up at any time
# -----------------------------------------------------------------------------
# module "sftp_customer_user" {
#   source        = "github.com/binbashar/terraform-aws-sftp-user.git?ref=v1.0.0"
#   for_each = toset(var.customers)

#   sftp_server_id            = module.customer_sftp[each.key].id
#   #sftp_server_id            = module.customer_sftp[each.key].aws_transfer_server.main.id

#   # TODO: Create std key for example Ref Arch
#   ssh_public_keys           = ["ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQD3F6tyPEFEzV0LX3X8BsXdMsQz1x2cEikKDEY0aIj41qgxMCP/iteneqXSIFZBp5vizPvaoIR3Um9xK7PGoW8giupGn+EPuxIA4cDM4vzOqOkiMPhz5XK0whEjkVzTo4+S0puvDZuwIsdiW9mxhJc7tgBNL0cYlWSYVkz4G/fslNfRPW5mYAM49f4fhtxPb5ok4Q2Lg9dPKVHO/Bgeu5woMc7RY0p1ej6D4CKFE6lymSDJpW0YHX/wqE9+cfEauh7xZcG0q9t2ta6F6fmX0agvpFyZo8aFbXeUBr7osSCJNgvavWbM/06niWrOvYX2xwWdhXmXSrbX8ZbabVohBK41 example@example.com"]

#   # aws_transfer_user
#   user_name                 = each.key
#   role_name                 = "${each.key}-sftp-role"
#   home_directory_bucket     = data.terraform_remote_state.apps-devstg-storage-s3-bucket[each.key].outputs.customers_buckets
#   home_directory_key_prefix = "/"
#   allowed_actions = [
#     "s3:GetObject",
#     "s3:GetObjectACL",
#     "s3:PutObject",
#     "s3:PutObjectACL",
#   ]
#   tags = {
#     Customer = each.key
#   }
# }