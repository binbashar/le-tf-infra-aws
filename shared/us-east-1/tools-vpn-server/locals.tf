locals {
  tags = {
    Name               = "${var.prefix}-${var.name}"
    Terraform          = "true"
    Environment        = var.environment
    ScheduleStopDaily  = true
    ScheduleStartDaily = true
    Backup             = "True"
  }

  user_data = <<EOF
#!/bin/bash
echo "Hello Terraform! -> Installing pre-req packages here!"
apt-get update
apt-get install -y vim
echo "DONE"
EOF
}
