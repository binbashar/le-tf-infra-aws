locals {
  tags = {
    Terraform                                                                           = "true"
    Environment                                                                         = var.environment
    "kubernetes.io/cluster/${data.terraform_remote_state.vpc-eks.outputs.cluster_name}" = "shared"
    GithubRepo                                                                          = "terraform-aws-eks"
    GithubOrg                                                                           = "binbashar"
  }
}
