locals {
  tags = {
    Name               = var.name
    Terraform          = "true"
    Environment        = var.environment
    # ScheduleStopDaily  = true
    # ScheduleStartDaily = true
    Layer              = local.layer_name
    Project            = "atlantis"
    Owner              = "oj"
  }
}
