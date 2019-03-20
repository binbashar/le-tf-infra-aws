#
# Security Resources
#

#
# Security Groups
#
module "sg_private" {
  source = "git::git@github.com:binbashar/bb-devops-tf-modules.git//aws/sg-bb?ref=v0.5"

  // udp_ports        = "22,443,9100"
  security_group_name     = "${var.sg_private_name}"
  tcp_ports               = "${var.sg_private_tpc_ports}"
  cidrs                   = ["${var.sg_private_cidrs}"]
  vpc_id                  = "${data.terraform_remote_state.vpc.vpc_id}"

  tags                    = "${local.tags}"
}

module "sg_public" {
  source = "git::git@github.com:binbashar/bb-devops-tf-modules.git//aws/sg-bb?ref=v0.5"

  security_group_name     = "${var.sg_public_name}"
  tcp_ports               = "${var.sg_public_tpc_ports}"
  cidrs                   = ["${var.sg_public_cidrs}"]
  vpc_id                  = "${data.terraform_remote_state.vpc.vpc_id}"

  tags                    = "${local.tags}"
}

#
# Security Groups Temporary access
#
#======================================================================================================#
# NO MODULAR since we use count as conditional enabled flag
# https://stackoverflow.com/questions/50186380/variance-in-attributes-based-on-count-index-in-terraform
# https://github.com/hashicorp/terraform/issues/18923
# https://github.com/hashicorp/terraform/issues/953
#======================================================================================================#
#
resource "aws_security_group" "sg_public_temporary" {
  count       = "${var.sg_public_temporary_enabled}"
  name        = "${var.sg_public_temporary_name}"
  description = "Allow temporary access for ${var.sg_public_temporary_name} to ${element(var.sg_public_temporary_tpc_ports, count.index)}"
  vpc_id      = "${data.terraform_remote_state.vpc.vpc_id}"

  tags        = "${local.tags}"
}

resource "aws_security_group_rule" "ingress" {
  count           = "${length(var.sg_public_temporary_tpc_ports)}"
  type            = "ingress"
  from_port       = "${element(var.sg_public_temporary_tpc_ports, count.index)}"
  to_port         = "${element(var.sg_public_temporary_tpc_ports, count.index)}"
  protocol        = "tcp"
  cidr_blocks     = ["${var.sg_public_temporary_cidrs}"]
  description     = "temporary public access"

  security_group_id = "${aws_security_group.sg_public_temporary.id}"
}
