locals {

  #================================#
  # Naming                         #
  #================================#
  name_suffix = "eks-training"

  cluster_name = "${var.project}-${var.environment}-${local.name_suffix}"

  tags = {
    Terraform   = "true"
    Project     = var.project
    Environment = var.environment
  }
}
