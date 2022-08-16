resource "null_resource" "default_resources" {
  count = var.enable_inspector ? 1 : 0
  provisioner "local-exec" {
    command = "aws inspector2 update-organization-configuration --auto-enable ec2=false,ecr=false --profile ${var.profile} --region ${var.region}"
  }
}
###
# Admin account config
###
resource "null_resource" "enable_admin_account" {
  count = var.enable_inspector ? 1 : 0
  provisioner "local-exec" {
    command = "aws inspector2 enable --account-ids ${var.accounts.security.id} --resource-types ECR --profile ${var.profile} --region ${var.region}"
  }
}
###
# Member account config, first associate next enable.
###
resource "null_resource" "associate_account" {
  for_each = { for k, v in local.inspector_members : k => v if var.enable_inspector }
  provisioner "local-exec" {
    command = "aws inspector2 associate-member --account-id ${var.accounts["${each.value}"].id} --profile ${var.profile} --region ${var.region}"
  }
  depends_on = [null_resource.enable_admin_account]
}
resource "null_resource" "enable_account" {
  for_each = { for k, v in local.inspector_members : k => v if var.enable_inspector }
  provisioner "local-exec" {
    command = "aws inspector2 enable --account-ids ${var.accounts["${each.value}"].id} --resource-types ECR EC2 --profile ${var.profile} --region ${var.region}"
  }
  depends_on = [null_resource.enable_admin_account, null_resource.associate_account]
}

###
# Member account config, first disable next disassociate.
###
resource "null_resource" "disable_account" {
  for_each = { for k, v in local.inspector_members : k => v if !var.enable_inspector }
  provisioner "local-exec" {
    command = "aws inspector2 disable --account-ids ${var.accounts["${each.value}"].id} --resource-types ECR EC2 --profile ${var.profile} --region ${var.region}"
  }
}
resource "null_resource" "disassociate_account" {
  for_each = { for k, v in local.inspector_members : k => v if !var.enable_inspector }
  provisioner "local-exec" {
    command = "aws inspector2 disassociate-member --account-id ${var.accounts["${each.value}"].id} --profile ${var.profile} --region ${var.region}"
  }
  depends_on = [null_resource.disable_account]
}
###
# Admin account config
###
resource "null_resource" "disable_admin_account" {
  count = var.enable_inspector ? 0 : 1
  provisioner "local-exec" {
    command = "aws inspector2 disable --account-ids ${var.accounts.security.id} --resource-types ECR EC2 --profile ${var.profile} --region ${var.region}"
  }
  depends_on = [null_resource.disable_account, null_resource.disassociate_account]
}
