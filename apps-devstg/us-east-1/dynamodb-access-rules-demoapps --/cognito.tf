resource "aws_cognito_user_pool" "user_pool" {
  name = local.cognitoname

  # schema {
  #   name                = "email"
  #   attribute_data_type = "String"
  #   mutable             = true
  #   required            = true
  #   string_attribute_constraints {
  #     min_length = 1
  #     max_length = 2048
  #   }
  # }

  schema {
    name                = "user_id"
    attribute_data_type = "String"
    mutable             = true
    required            = false
    string_attribute_constraints {
      min_length = 0
      max_length = 500
    }
  }

  tags = local.tags
}

resource "aws_cognito_user_pool_client" "user_pool_client" {
  name         = "${local.cognitoname}-ClientAppClient"
  user_pool_id = aws_cognito_user_pool.user_pool.id
  explicit_auth_flows = [
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_ADMIN_USER_PASSWORD_AUTH",
    "ALLOW_CUSTOM_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH"
  ]
  # The Admin flow also requires the client secret to be disabled for client-side use,
  # but since you are running it from a secure backend, it should be enabled:
  generate_secret = true # Recommended for Admin flows from a trusted backend
}

resource "aws_cognito_identity_pool" "identity_pool" {
  identity_pool_name               = "${local.cognitoname}-ClientFederatedIdentityPool"
  allow_unauthenticated_identities = false

  cognito_identity_providers {
    client_id               = aws_cognito_user_pool_client.user_pool_client.id
    provider_name           = "cognito-idp.${var.region}.amazonaws.com/${aws_cognito_user_pool.user_pool.id}"
    server_side_token_check = true
  }

  lifecycle {
    replace_triggered_by = [
      aws_cognito_user_pool.user_pool.id # Recreate if the User Pool ID changes
    ]
  }

}
resource "aws_cognito_identity_pool_roles_attachment" "roles_attachment" {
  identity_pool_id = aws_cognito_identity_pool.identity_pool.id

  roles = {
    "authenticated" = aws_iam_role.authenticated_role.arn
  }
  role_mapping {
    identity_provider         = "cognito-idp.${var.region}.amazonaws.com/${aws_cognito_user_pool.user_pool.id}:${aws_cognito_user_pool_client.user_pool_client.id}"
    type                      = "Token"
    ambiguous_role_resolution = "AuthenticatedRole"
  }
}
resource "aws_cognito_identity_pool_provider_principal_tag" "principal_tag" {
  identity_pool_id       = aws_cognito_identity_pool.identity_pool.id
  identity_provider_name = "cognito-idp.${var.region}.amazonaws.com/${aws_cognito_user_pool.user_pool.id}"
  use_defaults           = false
  principal_tags = {
    userId = "custom:user_id"
    # "userId"               = "$${TokenClaim:custom:user_id}"
  }
}