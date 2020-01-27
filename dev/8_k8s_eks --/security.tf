resource "aws_security_group" "all_worker_mgmt" {
  count = var.create_sg_eks_workers_customer == true ? 1 : 0

  name_prefix = "all_worker_management"
  vpc_id      = data.terraform_remote_state.vpc-eks.outputs.vpc_id

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"

    cidr_blocks = data.terraform_remote_state.vpc-eks.outputs.worker_mgmt_subnets_cidr[0]
  }
}
