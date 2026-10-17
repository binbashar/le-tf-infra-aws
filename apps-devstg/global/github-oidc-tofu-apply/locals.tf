locals {
  github_oidc_issuer_url = "https://token.actions.githubusercontent.com"
  github_repository      = "binbashar/le-tf-infra-aws"
  # Immutable IDs: a renamed or recreated repository does not inherit the trust.
  github_repository_id       = "175842832"
  github_repository_owner_id = "31255874"

  # The apply runs from a PR comment (issue_comment), which GitHub always runs from
  # the default branch's workflow file, behind the protected tofu-apply environment.
  github_environment       = "tofu-apply"
  github_allowed_ref       = "refs/heads/master"
  github_job_workflow_refs = ["${local.github_repository}/.github/workflows/tofu-apply.yml@refs/heads/master"]

  github_actions_opentofu_apply_role_name     = "GitHubActionsOpenTofuApply"
  github_actions_opentofu_apply_policy_name   = "GitHubActionsOpenTofuApply"
  github_actions_opentofu_apply_boundary_name = "GitHubActionsOpenTofuApplyBoundary"

  # Layers the apply role may change in this account, keyed by repository path,
  # with the backend key from each layer's config.tf. Each entry also needs the
  # provider writes it requires, in an apply-target-<layer>.tf file.
  apply_targets = {
    "apps-devstg/global/cli-test-layer" = {
      state_key = "apps-devstg/cli-test-layer/terraform.tfstate"
    }
  }

  tags = {
    Terraform    = "true"
    Environment  = var.environment
    Layer        = local.layer_name
    Name         = "github-oidc-tofu-apply"
    "aws-apn-id" = local.prm_apn_id
  }
}
