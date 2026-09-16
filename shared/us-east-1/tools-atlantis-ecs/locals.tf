locals {
  tags = {
    Name        = var.name
    Terraform   = "true"
    Environment = var.environment
    # ScheduleStopDaily  = true
    # ScheduleStartDaily = true
    Layer        = local.layer_name
    Project      = "atlantis"
    Owner        = "oj"
    "aws-apn-id" = local.prm_apn_id
  }
}
