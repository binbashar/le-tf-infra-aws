resource "aws_security_group" "eskibana" {
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id
  name        = local.tags["Name"]
  description = "Allow inbound traffic from Security Groups and CIDRs. Allow all outbound traffic"
  tags        = local.tags
}

resource "aws_security_group_rule" "ingress_shared_vpc" {
  security_group_id = aws_security_group.eskibana.id
  description       = "Allow inbound traffic from Shared VPC"
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = [data.terraform_remote_state.vpc.outputs.vpc_cidr_block]
}

resource "aws_security_group_rule" "ingress_es_shared_vpc" {
  security_group_id = aws_security_group.eskibana.id
  description       = "Allow inbound traffic from Shared VPC"
  type              = "ingress"
  from_port         = 9200
  to_port           = 9200
  protocol          = "tcp"
  cidr_blocks       = [data.terraform_remote_state.vpc.outputs.vpc_cidr_block]
}

resource "aws_security_group_rule" "ingress_eks_demoapps_vpc" {
  security_group_id = aws_security_group.eskibana.id
  description       = "Allow inbound traffic from EKS DemoApps VPC"
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = [data.terraform_remote_state.apps-devstg-eks-demoapps-network.outputs.vpc_cidr_block]
}

resource "aws_security_group_rule" "ingress_es_eks_demoapps_vpc" {
  security_group_id = aws_security_group.eskibana.id
  description       = "Allow inbound traffic from EKS DemoApps VPC"
  type              = "ingress"
  from_port         = 9200
  to_port           = 9200
  protocol          = "tcp"
  cidr_blocks       = [data.terraform_remote_state.apps-devstg-eks-demoapps-network.outputs.vpc_cidr_block]
}

resource "aws_security_group_rule" "egress_all" {
  security_group_id = aws_security_group.eskibana.id
  description       = "Allow all egress traffic"
  type              = "egress"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}
