#
# IAM Role for ECS Blue-Green Deployments
# Required for ECS to manage ALB target groups during deployment
#
resource "aws_iam_role" "ecs_blue_green" {
  count = var.ecs_deployment_type == "BLUE_GREEN" ? 1 : 0

  name = "${local.name}-ecs-blue-green-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = [
          "ecs-tasks.amazonaws.com",
          "ecs.amazonaws.com"
        ]
      }
    }]
  })

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "ecs_blue_green" {
  count = var.ecs_deployment_type == "BLUE_GREEN" ? 1 : 0

  role       = aws_iam_role.ecs_blue_green[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonECSInfrastructureRolePolicyForLoadBalancers"
}
