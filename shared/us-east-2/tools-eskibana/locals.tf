locals {
  tags = {
    Name              = "${var.prefix}-${var.name}"
    Terraform         = "true"
    Environment       = var.environment
    ScheduleStopDaily = true
  }
}
