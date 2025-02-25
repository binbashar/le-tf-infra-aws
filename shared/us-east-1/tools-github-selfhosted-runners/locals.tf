locals {
  tags = {
    Name        = "infra-github-selfhosted-runners"
    Terraform   = "true"
    Environment = var.environment
    Layer       = local.layer_name
  }
}

locals {
  secrets = {
    github_app_key_base64     = data.vault_generic_secret.github_app_selfhosted_runners.data["github_app_key_base64"]
    github_app_id             = data.vault_generic_secret.github_app_selfhosted_runners.data["github_app_id"]
    github_app_client_id      = data.vault_generic_secret.github_app_selfhosted_runners.data["github_app_client_id"]
    github_app_client_secret  = data.vault_generic_secret.github_app_selfhosted_runners.data["github_app_client_secret"]
    github_app_webhook_secret = data.vault_generic_secret.github_app_selfhosted_runners.data["github_app_webhook_secret"]
  }
}
