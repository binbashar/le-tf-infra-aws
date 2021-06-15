#
# Role: Cluster Autoscaler
#
module "role_cluster_autoscaler" {
  source = "github.com/binbashar/terraform-aws-iam.git//modules/iam-assumable-role-with-oidc?ref=v4.1.0"

  create_role  = true
  role_name    = "demoapps-cluster-autoscaler"
  provider_url = replace(data.terraform_remote_state.apps-devstg-eks-demoapps-cluster.outputs.cluster_oidc_issuer_url, "https://", "")

  role_policy_arns = [
    aws_iam_policy.demoapps_cluster_autoscaler.arn
  ]
  oidc_fully_qualified_subjects = [
    "system:serviceaccount:monitoring:autoscaler-aws-cluster-autoscaler"
  ]

  tags = {
    Subject = "cluster-autoscaler"
  }
}
