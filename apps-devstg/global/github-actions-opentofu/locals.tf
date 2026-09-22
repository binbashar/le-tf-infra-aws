locals {
  github_oidc_issuer_url = "https://token.actions.githubusercontent.com"
  github_repository      = "binbashar/le-tf-infra-aws"
  github_environment     = "tofu-plan-poc"

  # The repository currently uses GitHub's classic default OIDC subject format.
  # Immutable repository and owner IDs add rename-resistant checks alongside it.
  github_oidc_subject                         = "repo:${local.github_repository}:environment:${local.github_environment}"
  github_repository_id                        = "175842832"
  github_repository_owner_id                  = "31255874"
  github_oidc_allowed_refs                    = ["refs/heads/master", "refs/pull/*/merge"]
  github_actions_opentofu_plan_role_name      = "GitHubActionsOpenTofuPlan"
  github_actions_opentofu_plan_policy_name    = "GitHubActionsOpenTofuPlan"
  github_actions_opentofu_noop_role_name      = "GitHubActionsOpenTofuNoopPlan"
  github_actions_opentofu_noop_policy_name    = "GitHubActionsOpenTofuNoopPlan"
  github_actions_opentofu_bedrock_role_name   = "GitHubActionsOpenTofuBedrock"
  github_actions_opentofu_bedrock_policy_name = "GitHubActionsOpenTofuBedrock"

  target_state_key      = "apps-devstg/cli-test-layer/terraform.tfstate"
  target_role_name      = "LeverageTest"
  target_policy_name    = "leverage_test"
  noop_target_state_key = "apps-devstg/github-actions-opentofu/terraform.tfstate"

  # Verified with a read-only GetInferenceProfile call before this policy was
  # authored. InvokeModel evaluates both this system inference profile and its
  # destination foundation models.
  bedrock_model_id              = "us.anthropic.claude-sonnet-4-6"
  bedrock_foundation_model      = "anthropic.claude-sonnet-4-6"
  bedrock_destination_regions   = ["us-east-1", "us-east-2", "us-west-2"]
  bedrock_inference_profile_arn = "arn:${data.aws_partition.current.partition}:bedrock:${var.region}:${data.aws_caller_identity.current.account_id}:inference-profile/${local.bedrock_model_id}"
  bedrock_foundation_model_arns = [
    for region in local.bedrock_destination_regions :
    "arn:${data.aws_partition.current.partition}:bedrock:${region}::foundation-model/${local.bedrock_foundation_model}"
  ]

  tags = {
    Terraform    = "true"
    Environment  = var.environment
    Layer        = local.layer_name
    Name         = "github-actions-opentofu"
    "aws-apn-id" = local.prm_apn_id
  }
}
