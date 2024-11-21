#------------------------------------------------------------------------------
# EFS
# Create a file system to be used by EKS.
# (https://github.com/kubernetes-sigs/aws-efs-csi-driver/)
#------------------------------------------------------------------------------
# Requirements:
#   - Install the EFS CSI EKS Add-on via the "cluster" layer
#------------------------------------------------------------------------------
# TODO
#   - Use encrypted file systems
#   - Test replication and backups
#------------------------------------------------------------------------------
module "example_efs_file_system" {
  source = "github.com/terraform-aws-modules/terraform-aws-efs.git?ref=v1.3.1"

  # General specs
  name             = "eks-example"
  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"

  # Use encrypted if necessary
  # encrypted      = true
  # kms_key_arn    = "arn:aws:kms:eu-west-1:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab"

  # Define mount targets
  mount_targets = {
    for idx, subnet_id in data.terraform_remote_state.cluster-vpc.outputs.private_subnets :
    idx => {
      "subnet_id" = subnet_id
    }
  }

  # Create security group and rules
  security_group_description = "Example EKS EFS"
  security_group_vpc_id      = data.terraform_remote_state.cluster-vpc.outputs.vpc_id
  security_group_rules = {
    eks_vpc_private_subnets = {
      description = "Allow EKS VPC private subnets"
      cidr_blocks = data.terraform_remote_state.cluster-vpc.outputs.private_subnets_cidr
    }
  }

  # Enable backup policy if necessary
  enable_backup_policy = false

  # Enable cross-region replication if necessary
  # create_replication_configuration = true
  # replication_configuration_destination = {
  #  region = var.region_secondary
  # }

  # Make sure you know what you are doing when using file system policies since
  # it is recommended that you do that but it might complicate the setup
  attach_policy = false

  tags = local.tags
}
