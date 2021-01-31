#
# AppsDevStg EKS OpenID Connect Provider
#
resource "aws_iam_openid_connect_provider" "apps_devstg_eks" {
  client_id_list  = ["sts.amazonaws.com"]
  url             = data.terraform_remote_state.cluster-apps-devstg-eks.outputs.cluster_oidc_issuer_url
  # NOTE: Thumbprint of Root CA for EKS OIDC, Valid until 2037
  thumbprint_list = ["9e99a48a9960b14926bb7f3b02e22da2b0ab7280"]
}
