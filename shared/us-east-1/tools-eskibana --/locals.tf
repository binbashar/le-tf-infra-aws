locals {
  tags = {
    Name              = "${var.prefix}-${var.name}"
    Terraform         = "true"
    Environment       = var.environment
    ScheduleStopDaily = true
    Layer             = local.layer_name
    "aws-apn-id"      = local.prm_apn_id
  }
}
