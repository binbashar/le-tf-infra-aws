resource "null_resource" "ram_enable_sharing_with_aws_organization" {
  provisioner "local-exec" {
    command = "aws ram enable-sharing-with-aws-organization --profile ${var.profile} --region ${var.region}"
  }
}
