locals {
  aws_oidc_github_issuer_url = "https://token.actions.githubusercontent.com"
}

resource "aws_iam_openid_connect_provider" "aws_github_oidc" {
  url = local.aws_oidc_github_issuer_url

  client_id_list = [
    "sts.amazonaws.com",
  ]

  # Obtained from the certificate of the url, see here for more details https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_oidc_verify-thumbprint.html
  # Alternatively this can also be obtained by the aws managagement console when creading an oidc provider and use the "Get Thumbprint button"
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1","1c58a3a8518e8759bf075b76b750d4f2df264fcd","f879abce0008e4eb126e0097e46620f5aaae26ad"]
}
