#
# Role: cert-manager for EKS OIDC
#
module "role_certmanager" {
  source = "github.com/binbashar/terraform-aws-iam.git//modules/iam-assumable-role-with-oidc?ref=v4.1.0"

  providers = {
    aws = aws.shared
  }

  create_role  = true
  role_name    = "${local.prefix}-certmanager"
  provider_url = replace(data.terraform_remote_state.apps-devstg-eks-dr-cluster.outputs.cluster_oidc_issuer_url, "https://", "")

  role_policy_arns = [
    aws_iam_policy.certmanager_binbash_com_ar.arn
  ]
  oidc_fully_qualified_subjects = [
    "system:serviceaccount:certmanager:certmanager"
  ]

  tags = {
    Subject = "certmanager"
    Purpose = "eks-oidc"
  }
}

#
# Role: external-dns (private) for EKS OIDC
#
module "role_externaldns_private" {
  source = "github.com/binbashar/terraform-aws-iam.git//modules/iam-assumable-role-with-oidc?ref=v4.1.0"

  providers = {
    aws = aws.shared
  }

  create_role  = true
  role_name    = "${local.prefix}-externaldns-private"
  provider_url = replace(data.terraform_remote_state.apps-devstg-eks-dr-cluster.outputs.cluster_oidc_issuer_url, "https://", "")

  role_policy_arns = [
    aws_iam_policy.externaldns_aws_binbash_com_ar.arn
  ]
  oidc_fully_qualified_subjects = [
    "system:serviceaccount:externaldns:externaldns-private"
  ]

  tags = {
    Subject = "externaldns-private"
    Purpose = "eks-oidc"
  }
}

#
# Role: external-dns (public) for EKS OIDC
#
module "role_externaldns_public" {
  source = "github.com/binbashar/terraform-aws-iam.git//modules/iam-assumable-role-with-oidc?ref=v4.1.0"

  providers = {
    aws = aws.shared
  }

  create_role  = true
  role_name    = "${local.prefix}-externaldns-public"
  provider_url = replace(data.terraform_remote_state.apps-devstg-eks-dr-cluster.outputs.cluster_oidc_issuer_url, "https://", "")

  role_policy_arns = [
    aws_iam_policy.externaldns_binbash_com_ar.arn
  ]
  oidc_fully_qualified_subjects = [
    "system:serviceaccount:externaldns:externaldns-public"
  ]

  tags = {
    Subject = "externaldns-public"
    Purpose = "eks-oidc"
  }
}

#
# Role: Cluster Autoscaler
#
module "role_cluster_autoscaler" {
  source = "github.com/binbashar/terraform-aws-iam.git//modules/iam-assumable-role-with-oidc?ref=v4.1.0"

  create_role  = true
  role_name    = "${local.prefix}-cluster-autoscaler"
  provider_url = replace(data.terraform_remote_state.apps-devstg-eks-dr-cluster.outputs.cluster_oidc_issuer_url, "https://", "")

  role_policy_arns = [
    aws_iam_policy.cluster_autoscaler.arn
  ]
  oidc_fully_qualified_subjects = [
    "system:serviceaccount:monitoring:autoscaler-aws-cluster-autoscaler"
  ]

  tags = {
    Subject = "cluster-autoscaler"
  }
}
