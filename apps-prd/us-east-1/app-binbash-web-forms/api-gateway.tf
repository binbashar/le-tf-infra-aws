#
# HTTP API (not REST). One route, one integration, no authorizer — the endpoint is
# public by design; a job applicant has no credentials.
#
# CORS IS CONFIGURED HERE AND NOWHERE ELSE. The Lambda deliberately returns no
# Access-Control-* headers: API Gateway adds them to every response including the
# function's own, and two Access-Control-Allow-Origin headers make a browser
# reject the response outright.
#
resource "aws_apigatewayv2_api" "forms" {
  name          = local.api_name
  protocol_type = "HTTP"
  description   = "Public form endpoints for www.binbash.co (static export, no server of its own)"
  tags          = local.tags

  cors_configuration {
    allow_origins = var.allowed_origins
    allow_methods = ["POST", "OPTIONS"]
    allow_headers = ["content-type"]
    max_age       = 3600
  }
}

resource "aws_apigatewayv2_integration" "careers_application" {
  api_id                 = aws_apigatewayv2_api.forms.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.careers_application.invoke_arn
  payload_format_version = "2.0"
  timeout_milliseconds   = 10000
}

resource "aws_apigatewayv2_route" "careers_application" {
  api_id    = aws_apigatewayv2_api.forms.id
  route_key = local.careers_route
  target    = "integrations/${aws_apigatewayv2_integration.careers_application.id}"
}

#
# Auto-deployed default stage. The throttle is the anti-abuse layer the design
# chose in place of a WAF: it is stage-wide, so it bounds total spend rather than
# per-IP behaviour. Combined with the Lambda's reserved concurrency of 5, a flood
# costs a bounded amount and cannot reach SES faster than 5 rps.
#
resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.forms.id
  name        = "$default"
  auto_deploy = true
  tags        = local.tags

  default_route_settings {
    throttling_rate_limit  = var.throttle_rate_limit
    throttling_burst_limit = var.throttle_burst_limit
  }

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_access.arn
    format = jsonencode({
      requestId               = "$context.requestId"
      ip                      = "$context.identity.sourceIp"
      requestTime             = "$context.requestTime"
      routeKey                = "$context.routeKey"
      status                  = "$context.status"
      responseLength          = "$context.responseLength"
      integrationErrorMessage = "$context.integrationErrorMessage"
    })
  }
}

resource "aws_cloudwatch_log_group" "api_access" {
  name              = "/aws/apigateway/${local.api_name}"
  retention_in_days = var.log_retention_days
  tags              = local.tags
}

#
# Scoped to this API's execution ARN, so no other API can invoke the function.
#
resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowExecutionFromApiGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.careers_application.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.forms.execution_arn}/*/*"
}
