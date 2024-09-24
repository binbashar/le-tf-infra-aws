module "secrets" {
  source = "github.com/binbashar/terraform-aws-secrets-manager.git?ref=0.11.0"

  # The secret management is handled via AWS Console
  unmanaged = true

  secrets = {
    "/data-science/genai-llm-rag-demo" = {
      recovery_window_in_days = 0
      secret_key_value        = {} # values are stored via AWS Console
    }
  }
}

