#
# GitHub Actions OIDC deploy identity: the app repo CI publishes a new build
# by assuming this least-privilege role (no long-lived keys) to `aws s3 sync`
# the static export and create a CloudFront invalidation.
#
locals {
  github_oidc_issuer_url = "https://token.actions.githubusercontent.com"

  # Trust scoped to the app repo + production branch
  github_oidc_allowed_subject = "repo:${var.github_repository}:ref:refs/heads/${var.github_branch}"

  github_oidc_provider_arn = (
    var.create_github_oidc_provider
    ? aws_iam_openid_connect_provider.github[0].arn
    : data.aws_iam_openid_connect_provider.github[0].arn
  )
}

#
# GitHub OIDC identity provider (one per account). Created here while no other
# layer in apps-prd owns it; see var.create_github_oidc_provider and issue #1081.
#
resource "aws_iam_openid_connect_provider" "github" {
  count = var.create_github_oidc_provider ? 1 : 0

  url = local.github_oidc_issuer_url

  client_id_list = [
    "sts.amazonaws.com",
  ]

  # Obtained from the certificate of the url, see here for more details https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_oidc_verify-thumbprint.html
  # Alternatively this can also be obtained by the aws managagement console when creading an oidc provider and use the "Get Thumbprint button"
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1", "1c58a3a8518e8759bf075b76b750d4f2df264fcd", "f879abce0008e4eb126e0097e46620f5aaae26ad"]

  tags = local.tags
}

data "aws_iam_openid_connect_provider" "github" {
  count = var.create_github_oidc_provider ? 0 : 1

  url = local.github_oidc_issuer_url
}

#
# Deploy role: assumable only by the app repo production branch via OIDC
#
data "aws_iam_policy_document" "github_actions_trust" {
  statement {
    sid     = "GithubActionsAssumeRoleWithIdp"
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [local.github_oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = [local.github_oidc_allowed_subject]
    }
  }
}

resource "aws_iam_role" "github_actions_deploy" {
  name               = "${var.project}-${var.environment}-${local.app_subdomain}-github-actions-oidc"
  description        = "GitHub OIDC deploy role for ${local.app_fqdn} (s3 sync + CloudFront invalidation)"
  assume_role_policy = data.aws_iam_policy_document.github_actions_trust.json
  tags               = local.tags
}

#
# Least privilege: sync the site bucket + invalidate the distribution, nothing else
#
data "aws_iam_policy_document" "github_actions_deploy" {
  statement {
    sid    = "AllowSiteBucketList"
    effect = "Allow"
    actions = [
      "s3:GetBucketLocation",
      "s3:ListBucket",
    ]
    resources = [module.aws_startups_accelerate.s3_bucket_arn]
  }

  statement {
    sid    = "AllowSiteBucketSync"
    effect = "Allow"
    actions = [
      "s3:DeleteObject",
      "s3:GetObject",
      "s3:PutObject",
    ]
    resources = ["${module.aws_startups_accelerate.s3_bucket_arn}/*"]
  }

  statement {
    sid    = "AllowCloudFrontInvalidation"
    effect = "Allow"
    actions = [
      "cloudfront:CreateInvalidation",
      "cloudfront:GetInvalidation",
    ]
    resources = [module.aws_startups_accelerate.cf_arn]
  }
}

resource "aws_iam_policy" "github_actions_deploy" {
  name        = "${var.project}-${var.environment}-${local.app_subdomain}-github-actions-oidc"
  description = "GitHub OIDC deploy permissions for ${local.app_fqdn}"
  policy      = data.aws_iam_policy_document.github_actions_deploy.json
  tags        = local.tags
}

resource "aws_iam_role_policy_attachment" "github_actions_deploy" {
  role       = aws_iam_role.github_actions_deploy.name
  policy_arn = aws_iam_policy.github_actions_deploy.arn
}
