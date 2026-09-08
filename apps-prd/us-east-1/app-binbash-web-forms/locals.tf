locals {
  # DNS — the API's public name. The zone itself lives in the shared account.
  public_domain = "binbash.co"
  forms_fqdn    = "forms.${local.public_domain}"

  app_name      = "binbash-web-forms"
  function_name = "${var.project}-${var.environment}-careers-application"
  api_name      = "${var.project}-${var.environment}-${local.app_name}"

  # The one route this API serves.
  careers_route = "POST /careers-application"

  # Namespace for this layer's own CloudWatch metrics (monitoring.tf). Must not
  # start with "AWS/" — that prefix is reserved for AWS's own metrics.
  metric_namespace = "${var.project}-${var.environment}/${local.app_name}"

  tags = {
    Terraform   = "true"
    Environment = var.environment
    Layer       = local.layer_name
  }
}
