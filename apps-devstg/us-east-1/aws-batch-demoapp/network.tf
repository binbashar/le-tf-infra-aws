#=============================================#
# Security group for jobs / container hosts   #
#=============================================#
# Batch jobs only start outbound connections (ECR, CloudWatch Logs, ECS, S3, Secrets Manager...),
# so there are no ingress rules. Use var.additional_security_group_ids to reach other resources
# (e.g. a database security group that allows this one).
resource "aws_security_group" "batch" {
  name        = "${local.name}-compute"
  description = "AWS Batch ${local.name} compute environment (egress only)"
  vpc_id      = local.vpc_id

  tags = merge(local.tags, { Name = "${local.name}-compute" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_egress_rule" "batch_all" {
  security_group_id = aws_security_group.batch.id
  description       = "Outbound access to AWS APIs and image registries"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"

  tags = local.tags
}
