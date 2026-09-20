locals {
  github_oidc_issuer_url = "https://token.actions.githubusercontent.com"
  github_repository      = "binbashar/le-tf-infra-aws"
  github_environment     = "tofu-plan-poc"

  # The repository currently uses GitHub's classic default OIDC subject format.
  # Immutable repository and owner IDs add rename-resistant checks alongside it.
  github_oidc_subject             = "repo:${local.github_repository}:environment:${local.github_environment}"
  github_repository_id            = "175842832"
  github_repository_owner_id      = "31255874"
  github_oidc_allowed_refs        = ["refs/heads/master", "refs/pull/*/merge"]
  github_actions_plan_role_name   = "GitHubActionsTofuPlan"
  github_actions_plan_policy_name = "GitHubActionsTofuPlan"

  pilot_state_key   = "apps-devstg/cli-test-layer/terraform.tfstate"
  pilot_role_name   = "LeverageTest"
  pilot_policy_name = "leverage_test"

  tags = {
    Terraform    = "true"
    Environment  = var.environment
    Layer        = local.layer_name
    Name         = "github-actions-tofu-plan"
    "aws-apn-id" = local.prm_apn_id
  }
}
