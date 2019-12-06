#
# EC2 Pritunl OpenVPN
#
module "ec2_openvpn" {
  source = "git::git@github.com:binbashar/terraform-aws-ec2-pritunl-vpn.git?ref=v0.0.10"

  environment                   = "${var.environment}"
  aws_ami_os_id                 = "${var.aws_ami_os_id}"
  aws_ami_os_owner              = "${var.aws_ami_os_owner}"
  instance_type                 = "${var.instance_type}"
  aws_vpc_id                    = "${data.terraform_remote_state.vpc.vpc_id}"
  aws_vpc_public_subnets        = ["${data.terraform_remote_state.vpc.public_subnets[0]}"]
  aws_route53_public_zone_id    = ["${data.terraform_remote_state.vpc.aws_public_zone_id[0]}"]
  volume_size                   = "${var.volume_size}"
  sg_private_name               = "${var.sg_private_name}"
  sg_private_tpc_ports          = "${var.sg_private_tpc_ports}"
  sg_private_udp_ports          = "${var.sg_private_udp_ports}"
  sg_private_cidrs              = "${var.sg_private_cidrs}"
  sg_public_name                = "${var.sg_public_name}"
  sg_public_tpc_ports           = "${var.sg_public_tpc_ports}"
  sg_public_udp_ports           = "${var.sg_public_udp_ports}"
  sg_public_cidrs               = "${var.sg_public_cidrs}"
  sg_public_temporary_enabled   = "${var.sg_public_temporary_enabled}"
  sg_public_temporary_name      = "${var.sg_public_temporary_name}"
  sg_public_temporary_tpc_ports = "${var.sg_public_temporary_tpc_ports}"
  sg_public_temporary_cidrs     = "${var.sg_public_temporary_cidrs}"
  aws_key_pair_name             = "${data.terraform_remote_state.security.aws_key_pair_name}"
  instance_dns_record_name_1    = "${var.instance_dns_record_name_1}"
  instance_dns_record_name_2    = "${var.instance_dns_record_name_2}"
  tags                          = "${local.tags}"
}

# Increse the suffix =+ 1 in order to get terraform re-executing the provioser module
# eg: ec2_provisioner_ansible_1 -> ec2_provisioner_ansible_2
# NOTE: consider "make init" command will be needed before "make plan" and "make apply" commands.
#
module "ec2_provisioner_ansible_1" {
  source = "git::git@github.com:binbashar/terraform-null-ansible.git?ref=v0.0.6"

  instance_ip_addr                             = "${module.ec2_openvpn.public_ip}"
  shell_cmds                                   = "${var.shell_cmds}"
  provisioner_user                             = "${var.provisioner_user}"
  provisioner_private_key_path                 = "${var.provisioner_private_key_path}"
  provisioner_private_key_relative_script_path = "${var.provisioner_private_key_relative_script_path}"
  provisioner_script_path                      = "${var.provisioner_script_path}"
  provisioner_script_tags_enable               = "${var.provisioner_script_tags_enable}"
  provisioner_script_tags                      = "${var.provisioner_script_tags}"
  provisioner_vault_pass_enabled               = "${var.provisioner_vault_pass_enabled}"
  provisioner_vault_pass_path                  = "${var.provisioner_vault_pass_path}"
}
