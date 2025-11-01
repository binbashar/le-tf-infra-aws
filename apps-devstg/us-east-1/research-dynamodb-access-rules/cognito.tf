resource "aws_cognito_user_pool" "user_pool" {
  name = local.cognitoname
  # ... other necessary settings like email configuration, required attributes, etc.
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
    provider_name           = "cognito-idp.us-east-1.amazonaws.com/${aws_cognito_user_pool.user_pool.id}"
    server_side_token_check = true
  }
}