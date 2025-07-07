data "aws_iam_roles" "devopsrole" {
  name_regex = ".*AWSReservedSSO_DevOps.*"
}
