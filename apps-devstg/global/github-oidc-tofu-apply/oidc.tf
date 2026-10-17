#
# The account's GitHub OIDC provider is owned by github-oidc-tofu-plan; an
# account can have only one provider per issuer, so this layer reads it.
#
data "aws_iam_openid_connect_provider" "github" {
  url = local.github_oidc_issuer_url
}

data "aws_iam_policy_document" "github_actions_opentofu_apply_trust" {
  statement {
    sid     = "GitHubActionsAssumeRoleWithWebIdentity"
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${local.github_repository}:environment:${local.github_environment}"]
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
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:ref"
      values   = [local.github_allowed_ref]
    }

    # Only the apply workflow file on master, not any workflow that targets the
    # tofu-apply environment. Fails closed if the claim is absent.
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:job_workflow_ref"
      values   = local.github_job_workflow_refs
    }
  }
}

resource "aws_iam_role" "github_actions_opentofu_apply" {
  name                 = local.github_actions_opentofu_apply_role_name
  description          = "Least-privilege OpenTofu apply role for GitHub Actions, scoped to allowlisted layers"
  assume_role_policy   = data.aws_iam_policy_document.github_actions_opentofu_apply_trust.json
  max_session_duration = 3600
  permissions_boundary = aws_iam_policy.github_actions_opentofu_apply_boundary.arn
}
