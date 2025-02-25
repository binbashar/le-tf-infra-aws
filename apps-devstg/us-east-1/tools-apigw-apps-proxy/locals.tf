locals {
  # Define the sites that have to be included
  sites_included = [
  ]

  # Define, for a given site, what apps should be excluded
  # apps_excluded = { app_name: [sites] }
  apps_excluded = { "task-svc" : [], "scheduler" : [], "mbot" : ["mysite"], "mbotsvc" : ["mysite"] }

  # Convert the clients/sites list to a sites list. Note that we are assuming
  # that all sites need to be enabled, no exclusions are being applied.
  sites = keys(transpose({
    for client, client_info in var.clients :
    client => [
      for site, site_info in client_info.sites : site if contains(local.sites_included, site)
    ]
  }))

  # Define the apps that will be handled (routed) by the API Gateway
  apps = [
    "scheduler",
    "mbot",
    "mbotsvc",
    "task-svc",
  ]
  multitenant_apps = [
    "task-svc"
  ]

  # The short environment name which is part of the apps' DNS names
  env = replace(var.environment, "apps-", "")

  # Public and private base domains
  public_domain  = "diligentrobots.io"
  private_domain = "aws.${local.public_domain}"

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

  tags = {
    Terraform   = "true"
    Environment = var.environment
  }
}
