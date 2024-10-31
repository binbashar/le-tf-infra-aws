
data "terraform_remote_state" "tools-vpn-server" {
  count = var.vpn_private_ip == null && var.create_acl_for_vpn_ip ? 1 : 0

  backend = "s3"
  config = {
    region  = var.region
    profile = "${var.project}-shared-devops"
    bucket  = "${var.project}-shared-terraform-backend"
    key     = "shared/vpn-server/terraform.tfstate"
  }
}

data "terraform_remote_state" "shared-vpcs" {
  for_each = local.shared_vpcs_default

  backend = "s3"
  config = {
    region  = lookup(each.value, "region")
    profile = lookup(each.value, "profile")
    bucket  = lookup(each.value, "bucket")
    key     = lookup(each.value, "key")
  }
}

