resource "null_resource" "enable_delegation" {
  count = var.enable_inspector ? 1 : 0
  provisioner "local-exec" {
    command = "aws inspector2 enable-delegated-admin-account --delegated-admin-account-id ${var.accounts.security.id} --profile ${var.profile} --region ${var.region}"
  }
}

resource "null_resource" "disable_delegation" {
  count = var.enable_inspector ? 0 : 1
  provisioner "local-exec" {
    command = "aws inspector2 disable-delegated-admin-account --delegated-admin-account-id ${var.accounts.security.id} --profile ${var.profile} --region ${var.region}"
  }
}
