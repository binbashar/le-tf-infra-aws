locals {
  # Define your secret and its properties here
  secrets = {
    "/repositories/demo-google-microservices/deploy_key" = {
      description             = "Repository: Google Microservices DemoApp - Deploy Key"
      recovery_window_in_days = 7
      secret_string           = "INITIAL_VALUE"
      kms_key_id              = data.terraform_remote_state.keys.outputs.aws_kms_key_id
    },

    "/repositories/le-demo-apps/deploy_key" = {
      description             = "Repository: Leverage Demo Applications - Deploy Key"
      recovery_window_in_days = 7
      secret_string           = "INITIAL_VALUE"
      kms_key_id              = data.terraform_remote_state.keys.outputs.aws_kms_key_id
    },

    "/notifications/argocd" = {
      description             = "Slack App Oauth token for ArgoCD notifications"
      recovery_window_in_days = 7
      secret_string           = "INITIAL_VALUE"
      kms_key_id              = data.terraform_remote_state.keys.outputs.aws_kms_key_id
    },

    "/notifications/slack/cost-reports" = {
      description             = "Slack Incoming Webhook Custom Integration for Cost Reports"
      recovery_window_in_days = 7
      secret_string           = "INITIAL_VALUE"
      kms_key_id              = data.terraform_remote_state.keys.outputs.aws_kms_key_id
      custom_policy_json = {
        sid    = "CostReportsLambda"
        effect = "Allow"
        principal = {
          "AWS" : "arn:aws:iam::${var.accounts.management.id}:role/bb-root-cost-report"
        }
        actions   = ["secretsmanager:GetSecretValue"],
        resources = ["*"]
      }
    },

    #
    # This secret was created based on the centralized secrets approach and the naming conventions
    # defined here: https://binbash.atlassian.net/wiki/spaces/BDPS/pages/2425978910/Secrets+Management+Conventions
    #
    "/devops/notifications/slack/monitoring" = {
      description             = "Slack Webhook for the tools monitoring notifications"
      recovery_window_in_days = 7
      secret_string           = "INITIAL_VALUE"
      kms_key_id              = data.terraform_remote_state.keys.outputs.aws_kms_key_id
    },

    "/devops/notifications/slack/security" = {
      description             = "Slack Webhook for the security notifications"
      recovery_window_in_days = 7
      secret_string           = "INITIAL_VALUE"
      kms_key_id              = data.terraform_remote_state.keys.outputs.aws_kms_key_id
    },

    "/devops/notifications/phone/notifications" = {
      description             = "Phone number for the security notifications"
      recovery_window_in_days = 7
      secret_string           = "INITIAL_VALUE"
      kms_key_id              = data.terraform_remote_state.keys.outputs.aws_kms_key_id
    },

    "/devops/monitoring/alertmanager" = {
      description             = "Slack webhook for Alertmanager notifications"
      recovery_window_in_days = 7
      secret_string           = "INITIAL_VALUE"
      kms_key_id              = data.terraform_remote_state.keys.outputs.aws_kms_key_id
    },

    "/devops/monitoring/grafana/administrator" = {
      description             = "Credentials for Grafana administrator user"
      recovery_window_in_days = 7
      secret_string           = "INITIAL_VALUE"
      kms_key_id              = data.terraform_remote_state.keys.outputs.aws_kms_key_id
    },

    "/devops/apps-devstg/database-aurora/administrator" = {
      description             = "Credentials for Aurora administrator user"
      recovery_window_in_days = 7
      secret_string           = "INITIAL_VALUE"
      kms_key_id              = data.terraform_remote_state.keys.outputs.aws_kms_key_id
    },

    "/devops/apps-devstg/database-mysql/administrator" = {
      description             = "Credentials for MySQL administrator user"
      recovery_window_in_days = 7
      secret_string           = "INITIAL_VALUE"
      kms_key_id              = data.terraform_remote_state.keys.outputs.aws_kms_key_id
    },
    "/devops/apps-devstg/elasticache-redis/auth_token" = {
      description             = "Password used to access Elasticache Redis protected server"
      recovery_window_in_days = 7
      secret_string           = "INITIAL_VALUE"
      kms_key_id              = data.terraform_remote_state.keys.outputs.aws_kms_key_id
    },
    "/devops/shared/atlantis" = {
      description             = "Atlantis required credentials"
      recovery_window_in_days = 7
      secret_string           = "INITIAL_VALUE"
      kms_key_id              = data.terraform_remote_state.keys.outputs.aws_kms_key_id
    },
  }

  # Define common tags here
  tags = {
    Terraform   = "true"
    Environment = var.environment
    Layer       = local.layer_name
  }
}
