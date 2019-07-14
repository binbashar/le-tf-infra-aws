#
# EC2 Jenkins vault
#
module "ec2_jenkins_vault" {
  source = "git::git@github.com:binbashar/terraform-aws-jenkins-vault.git?ref=v0.0.3"

  environment                         = "${var.environment}"
  dev_account_id                      = "${var.dev_account_id}"
  security_account_id                 = "${var.security_account_id}"
  shared_account_id                   = "${var.shared_account_id}"
  aws_ami_os_id                       = "${var.aws_ami_os_id}"
  aws_ami_os_owner                    = "${var.aws_ami_os_owner}"
  aws_iam_role_name_1                 = "${var.aws_iam_role_name_1}"
  aws_iam_role_name_2                 = "${var.aws_iam_role_name_2}"
  instance_type                       = "${var.instance_type}"
  aws_vpc_id                          = "${data.terraform_remote_state.vpc.vpc_id}"
  aws_vpc_private_subnets             = ["${data.terraform_remote_state.vpc.private_subnets[0]}"]
  aws_route53_internal_zone_id        = ["${data.terraform_remote_state.vpc.aws_internal_zone_id[0]}"]
  aws_route53_public_zone_id          = ["${data.terraform_remote_state.vpc.aws_public_zone_id[0]}"]
  volume_size_root                    = "${var.volume_size_root}"
  volume_size_extra_1                 = "${var.volume_size_extra_1}"
  volume_size_extra_2                 = "${var.volume_size_extra_2}"
  volume_az_extra                       = "${var.volume_az_extra}"
  aws_s3_bucket_name_1                = "${var.aws_s3_bucket_name_1}"
  aws_s3_bucket_name_2                = "${var.aws_s3_bucket_name_2}"
  sg_private_name                     = "${var.sg_private_name}"
  sg_private_tpc_ports                = "${var.sg_private_tpc_ports}"
  sg_private_udp_ports                = "${var.sg_private_udp_ports}"
  sg_private_cidrs                    = "${var.sg_private_cidrs}"
  aws_key_pair_name                   = "${data.terraform_remote_state.security.aws_key_pair_name}"
  aws_iam_instance_profile_jenkins_name = "${var.aws_iam_instance_profile_jenkins_name}"
  aws_iam_jenkins_assume_role_name      = "${var.aws_iam_jenkins_assume_role_name}"
  aws_iam_policy_jenkins_access_name    = "${var.aws_iam_policy_jenkins_access_name}"
  instance_dns_record_name_1          = "${var.instance_dns_record_name_1}"
  instance_dns_record_name_2          = "${var.instance_dns_record_name_2}"
  letsencrypt_dns_record_name         = "${var.letsencrypt_dns_record_name}"
  letsencrypt_dns_record_value        = "${var.letsencrypt_dns_record_value}"
  tags                                = "${local.tags}"
}
