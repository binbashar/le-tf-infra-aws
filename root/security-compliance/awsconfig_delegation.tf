resource "null_resource" "config_delegation" {
  provisioner "local-exec" {
    command = "aws organizations register-delegated-administrator --account-id ${var.security_account_id} --service-principal config.amazonaws.com  --profile ${var.profile} --region ${var.region}"
  }
}
