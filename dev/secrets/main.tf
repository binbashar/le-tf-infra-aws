#
# Dev to AWS SSM Passwords here
#
resource "aws_ssm_parameter" "bb_dev_tool_name_admin_password" {
    name  = "/bb/${var.environment}/too_name/admin_password"
    description  = "Binbash ${upper(var.environment)} Tool X Admin Password"
    type  = "SecureString"
    value = "${var.bb_dev_tool_admin_password}"

    tags = "${local.tags}"
}