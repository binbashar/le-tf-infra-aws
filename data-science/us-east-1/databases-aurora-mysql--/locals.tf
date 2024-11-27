locals {
  tags = {
    Name               = "aurora-demo"
    Terraform          = "true"
    Environment        = var.environment
    ScheduleStopDaily  = true
    ScheduleStartDaily = true
  }
}
