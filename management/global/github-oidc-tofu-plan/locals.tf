locals {
  github_oidc_issuer_url = "https://token.actions.githubusercontent.com"
  github_repository      = "binbashar/le-tf-infra-aws"
  github_environments = {
    plan = "tofu-plan"
  }

  # The repository currently uses GitHub's classic default OIDC subject format.
  github_oidc_subjects = {
    for purpose, environment in local.github_environments :
    purpose => "repo:${local.github_repository}:environment:${environment}"
  }
  github_repository_id                     = "175842832"
  github_repository_owner_id               = "31255874"
  github_oidc_allowed_refs                 = ["refs/heads/master", "refs/pull/*/merge"]
  github_actions_opentofu_plan_role_name   = "GitHubActionsOpenTofuPlan"
  github_actions_opentofu_plan_policy_name = "GitHubActionsOpenTofuPlan"

  # Layers the plan role may plan in this account, keyed by repository path,
  # with the backend key from each layer's config.tf. Each entry also needs the
  # provider reads its refresh requires, in a plan-target-<layer>.tf file.
  plan_targets = {
    "management/global/sso" = {
      state_key = "management/sso/terraform.tfstate"
    }
  }

  tags = {
    Terraform    = "true"
    Environment  = var.environment
    Layer        = local.layer_name
    Name         = "github-oidc-tofu-plan"
    "aws-apn-id" = local.prm_apn_id
  }
}
