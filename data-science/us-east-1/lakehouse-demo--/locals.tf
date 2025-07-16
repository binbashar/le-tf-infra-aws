locals {
  name = "${var.project}-${var.environment}-lake-house-demo"

  tags = {
    Name        = local.name
    Terraform   = "true"
    Environment = var.environment
    Layer       = local.layer_name
  }


  # Add additional IAM roles to this list to grant them usage access to the Redshift database.
  # Ref: https://docs.aws.amazon.com/redshift/latest/mgmt/query-editor-v2-glue.html
  # If the code is executed using SSO credentials, the ARN in data.aws_caller_identity.current.arn
  # will contain a string similar to "assumed-role/AWSReservedSSO_DevOps_abc123/username@mail.com".
  # To grant usage access to the role, we need to extract only the role name portion,
  # which is "AWSReservedSSO_DevOps_abc123" in this case.
  roles_to_grant_usage = [
    split("/", split(":", data.aws_caller_identity.current.arn)[5])[1], # Current user role
  ]
}
