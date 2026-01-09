locals {

  # ##########################################################
  # General variables

  tags = {
    Terraform   = "true"
    Environment = var.environment
  }

  cloudwatch_group_prefix = "/aws/apigateway/apigw-proxy-"

  url_apps_prefix = "/app"

  # The short environment name which is part of the apps' DNS names
  env = replace(var.environment, "apps-", "")

  private_domain_prefix = "intra"

  # Public and private base domains
  public_domain  = "${local.env}.aws.binbash.com.ar"
  private_domain = "${local.private_domain_prefix}.${local.public_domain}"

  # Log format
  log_format = jsonencode({
    "httpMethod" : "$context.httpMethod",
    "protocol" : "$context.protocol",
    "requestTime" : "$context.requestTime",
    "responseLength" : "$context.responseLength",
    "routeKey" : "$context.routeKey",
    "status" : "$context.status",
    "requestId" : "$context.requestId",
    "ip" : "$context.identity.sourceIp",
    "errorMessage" : "$context.error.message",
    "errorResponseType" : "$context.error.responseType",
    "integrationError" : "$context.integration.error",
    "integrationErrorMessage" : "$context.integrationErrorMessage"
  })

  # ##########################################################
  # Sites and Apps

  # Convert the clients/sites list to a sites list. Note that we are assuming
  # that all sites need to be enabled, no exclusions are being applied.
  # URL valid names, no dots
  sites = [
    "site1"
  ]

  # Define the apps that will be handled (routed) by the API Gateway
  apps = [
    "scheduler",
    "mbot",
    "mbotsvc",
    "task-svc",
  ]

}
