#
# Role: cert-manager for EKS OIDC -- Enable or update upon cluster creation.
#
module "role_cert_manager" {
  source = "github.com/binbashar/terraform-aws-iam.git//modules/iam-assumable-role-with-oidc?ref=v4.1.0"

  create_role  = true
  role_name    = "prd-cert-manager"
  provider_url = replace(data.terraform_remote_state.apps-prd-eks-cluster.outputs.cluster_oidc_issuer_url, "https://", "")

  role_policy_arns = [
    aws_iam_policy.cert_manager_binbash_com_ar.arn
  ]
  oidc_fully_qualified_subjects = [
    "system:serviceaccount:cert-manager:cert-manager"
  ]

  tags = {
    Subject = "cert-manager"
    Purpose = "eks-oidc"
  }
}

#
# Role: external-dns (private) for EKS OIDC -- Enable or update upon cluster creation.
#
module "role_external_dns_private" {
  source = "github.com/binbashar/terraform-aws-iam.git//modules/iam-assumable-role-with-oidc?ref=v4.1.0"

  create_role  = true
  role_name    = "prd-external-dns-private"
  provider_url = replace(data.terraform_remote_state.apps-prd-eks-cluster.outputs.cluster_oidc_issuer_url, "https://", "")

  role_policy_arns = [
    aws_iam_policy.external_dns_aws_binbash_com_ar.arn
  ]
  oidc_fully_qualified_subjects = [
    "system:serviceaccount:external-dns:external-dns-private"
  ]

  tags = {
    Subject = "external-dns-private"
    Purpose = "eks-oidc"
  }
}
#
#
# Role: external-dns (public) for EKS OIDC -- Enable or update upon cluster creation.
#
module "role_external_dns_public" {
  source = "github.com/binbashar/terraform-aws-iam.git//modules/iam-assumable-role-with-oidc?ref=v4.1.0"

  create_role  = true
  role_name    = "prd-external-dns-public"
  provider_url = replace(data.terraform_remote_state.apps-prd-eks-cluster.outputs.cluster_oidc_issuer_url, "https://", "")

  role_policy_arns = [
    aws_iam_policy.external_dns_public.arn
  ]
  oidc_fully_qualified_subjects = [
    "system:serviceaccount:external-dns:external-dns-public"
  ]

  tags = {
    Subject = "external-dns-public"
    Purpose = "eks-oidc"
  }
}
