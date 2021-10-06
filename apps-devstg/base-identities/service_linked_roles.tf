#
# Many AWS services require that a Service Linked Role is created before you
# proceed to creating some resources.
# Typically when you create such resources through the AWS console, Service
# Linked Roles are automatically created for you -- although that depends on
# your permissions at the moment.
# Now, that won't work if you try to create the resources through the AWS CLI
# or Terraform. For those cases you may need to create the roles explicitly.
#

resource "aws_iam_service_linked_role" "ecs" {
  aws_service_name = "ecs.amazonaws.com"
}
