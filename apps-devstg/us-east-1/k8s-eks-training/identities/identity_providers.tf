#
# OIDC Provider needed for roles in the Shared account
#
resource "aws_iam_openid_connect_provider" "shared" {
  provider        = aws.shared
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.shared.certificates[0].sha1_fingerprint]
  url             = data.terraform_remote_state.cluster.outputs.cluster_oidc_issuer_url
  tags            = local.tags
}

data "tls_certificate" "shared" {
  url = data.terraform_remote_state.cluster.outputs.cluster_oidc_issuer_url
}
