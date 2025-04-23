module "secrets" {
  source = "github.com/binbashar/terraform-aws-secrets-manager.git?ref=0.11.0"

  # The secret management is handled via AWS Console
  unmanaged = true

  secrets = {
    demo = {
      recovery_window_in_days = 0
      name_prefix             = "/data-science/genai-llm-rag-demo"
      secret_key_value        = {} # values are stored via AWS Console
    }
  }
}

