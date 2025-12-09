#
# Created for Github Self-hosted Runners but since it is a global role it is
# usually shared by other implementations. Hence it is declared here.
#
resource "aws_iam_service_linked_role" "spot" {
  aws_service_name = "spot.amazonaws.com"
}

# resource "aws_iam_service_linked_role" "autoscaling" {
#   aws_service_name = "autoscaling.amazonaws.com"
# }
