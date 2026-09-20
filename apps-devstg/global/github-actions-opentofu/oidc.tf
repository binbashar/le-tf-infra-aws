#
# Account-wide GitHub Actions OIDC provider.
#
# A read-only account audit found no provider for this issuer in apps-devstg.
# AWS validates GitHub against its trusted CA library; AWS provider 4.x still
# requires thumbprint_list, so this keeps the compatibility list already used
# by the repository's other GitHub OIDC providers.
#
resource "aws_iam_openid_connect_provider" "github" {
  url = local.github_oidc_issuer_url

  client_id_list = [
    "sts.amazonaws.com",
  ]

  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1c58a3a8518e8759bf075b76b750d4f2df264fcd",
    "f879abce0008e4eb126e0097e46620f5aaae26ad",
  ]

  lifecycle {
    prevent_destroy = true
  }
}

data "aws_iam_policy_document" "github_actions_opentofu_plan_trust" {
  statement {
    sid     = "GitHubActionsAssumeRoleWithWebIdentity"
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = [local.github_oidc_subject]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:environment"
      values   = [local.github_environment]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:repository_id"
      values   = [local.github_repository_id]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:repository_owner_id"
      values   = [local.github_repository_owner_id]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:ref"
      values   = local.github_oidc_allowed_refs
    }
  }
}

resource "aws_iam_role" "github_actions_opentofu_plan" {
  name                 = local.github_actions_opentofu_plan_role_name
  description          = "Read-only OpenTofu plan role for GitHub Actions"
  assume_role_policy   = data.aws_iam_policy_document.github_actions_opentofu_plan_trust.json
  max_session_duration = 3600
}
