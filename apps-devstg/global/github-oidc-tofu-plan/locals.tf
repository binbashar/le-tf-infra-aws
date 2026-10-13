locals {
  github_oidc_issuer_url = "https://token.actions.githubusercontent.com"
  github_repository      = "binbashar/le-tf-infra-aws"
  # GitHub environments each role trusts. The Bedrock steps run inside the plan
  # job, after its plan credentials are cleared, so both roles trust tofu-plan.
  github_environments = {
    plan    = ["tofu-plan"]
    bedrock = ["tofu-plan"]
  }

  # The repository currently uses GitHub's classic default OIDC subject format.
  # Immutable repository and owner IDs add rename-resistant checks alongside it.
  github_oidc_subjects = {
    for purpose, environments in local.github_environments :
    purpose => [
      for environment in environments :
      "repo:${local.github_repository}:environment:${environment}"
    ]
  }
  github_repository_id                        = "175842832"
  github_repository_owner_id                  = "31255874"
  github_oidc_allowed_refs                    = ["refs/heads/master", "refs/pull/*/merge"]
  github_actions_opentofu_plan_role_name      = "GitHubActionsOpenTofuPlan"
  github_actions_opentofu_plan_policy_name    = "GitHubActionsOpenTofuPlan"
  github_actions_opentofu_bedrock_role_name   = "GitHubActionsOpenTofuBedrock"
  github_actions_opentofu_bedrock_policy_name = "GitHubActionsOpenTofuBedrock"

  # Layers the plan role may plan in this account, keyed by repository path,
  # with the backend key from each layer's config.tf. Each entry also needs the
  # provider reads its refresh requires, in a plan-target-<layer>.tf file.
  plan_targets = {
    "apps-devstg/global/cli-test-layer" = {
      state_key = "apps-devstg/cli-test-layer/terraform.tfstate"
    }
  }

  # Verified with a read-only GetInferenceProfile call before this policy was
  # authored. InvokeModel evaluates both this system inference profile and its
  # destination foundation models.
  bedrock_model_id              = "us.anthropic.claude-haiku-5-5"
  bedrock_foundation_model      = "anthropic.claude-haiku-5-5"
  bedrock_destination_regions   = ["us-east-1", "us-east-2", "us-west-2"]
  bedrock_inference_profile_arn = "arn:${data.aws_partition.current.partition}:bedrock:${var.region}:${data.aws_caller_identity.current.account_id}:inference-profile/${local.bedrock_model_id}"
  bedrock_foundation_model_arns = [
    for region in local.bedrock_destination_regions :
    "arn:${data.aws_partition.current.partition}:bedrock:${region}::foundation-model/${local.bedrock_foundation_model}"
  ]

  # Second reviewed model, selected with the BEDROCK_MODEL_ID variable of the
  # tofu-plan-bedrock environment. Invoked directly, not through a profile.
  bedrock_nova_lite_model_id  = "amazon.nova-lite-v1:0"
  bedrock_nova_lite_model_arn = "arn:${data.aws_partition.current.partition}:bedrock:${var.region}::foundation-model/${local.bedrock_nova_lite_model_id}"

  tags = {
    Terraform    = "true"
    Environment  = var.environment
    Layer        = local.layer_name
    Name         = "github-oidc-tofu-plan"
    "aws-apn-id" = local.prm_apn_id
  }
}
