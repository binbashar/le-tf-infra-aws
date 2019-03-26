#
# EC2 Jenkins vault
#
module "ec2_jenkins_vault" {
  source = "git::git@github.com:binbashar/bb-devops-tf-modules.git//aws/ec2-jenkins-bb?ref=v0.5"

  environment                                   = "${var.environment}"
  dev_account_id                                = "${var.dev_account_id}"
  security_account_id                           = "${var.security_account_id}"
  shared_account_id                             = "${var.shared_account_id}"
  aws_ami_os_id                                 = "${var.aws_ami_os_id}"
  aws_ami_os_owner                              = "${var.aws_ami_os_owner}"
  instance_type                                 = "${var.instance_type}"
  aws_vpc_id                                    = "${data.terraform_remote_state.vpc.vpc_id}"
  aws_vpc_public_subnets                        = ["${data.terraform_remote_state.vpc.public_subnets[0]}"]
  aws_route53_internal_zone_id                  = ["${data.terraform_remote_state.vpc.aws_public_zone_id[0]}"]
  volume_size_root                              = "${var.volume_size_root}"
  volume_size_extra_1                           = "${var.volume_size_extra_1}"
  volume_size_extra_2                           = "${var.volume_size_extra_2}"
  sg_private_name                               = "${var.sg_private_name}"
  sg_private_tpc_ports                          = "${var.sg_private_tpc_ports}"
  sg_private_udp_ports                          = "${var.sg_private_udp_ports}"
  sg_private_cidrs                              = "${var.sg_private_cidrs}"
  aws_key_pair_name                             = "${data.terraform_remote_state.security.aws_key_pair_name}"
  instance_dns_record_name_1                    = "${var.instance_dns_record_name_1}"
  instance_dns_record_name_2                    = "${var.instance_dns_record_name_2}"
  tags                                          = "${local.tags}"
}
