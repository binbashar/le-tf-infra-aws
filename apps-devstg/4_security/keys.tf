resource "aws_key_pair" "compute-ssh-key" {
  key_name   = var.compute_ssh_key_name
  public_key = var.compute_ssh_public_key
}

module "kms_key" {
  source = "git::git@github.com:binbashar/terraform-aws-kms-key.git?ref=0.4.0"

  enabled                 = true
  namespace               = var.project
  stage                   = var.environment
  name                    = var.kms_key_name
  delimiter               = "-"
  description             = "KMS key for Dev Account"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  alias                   = "alias/${var.project}_${var.environment}_${var.kms_key_name}_key"

}