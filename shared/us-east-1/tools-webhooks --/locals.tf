locals {
  tags = {
    Name               = "infra-webhooks-proxy"
    Terraform          = "true"
    Environment        = var.environment
    ScheduleStopDaily  = true
    ScheduleStartDaily = true
    Layer              = local.layer_name
  }
}
