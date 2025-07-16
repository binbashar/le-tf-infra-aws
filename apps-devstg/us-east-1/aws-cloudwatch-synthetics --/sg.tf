# Security group for granting access from canary to targets
#
resource "aws_security_group" "target-canary-sg" {
  name        = "${var.project}-${var.environment}-target-canary-sg"
  description = "Allow TLS outbound traffic"
  vpc_id      = data.terraform_remote_state.local-vpcs.outputs.vpc_id

  #ingress {
  #  description = "TLS from VPC"
  #  from_port   = 443
  #  to_port     = 443
  #  protocol    = "tcp"
  #  cidr_blocks = ["0.0.0.0/0"]
  #}

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.tags
}
