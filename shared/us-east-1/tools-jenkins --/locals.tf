locals {
  tags = {
    Name              = "${var.prefix}-${var.name}"
    Terraform         = "true"
    Environment       = var.environment
    ScheduleStopDaily = true
    Layer             = local.layer_name
    "aws-apn-id"      = local.prm_apn_id
  }

  user_data = <<EOF
#!/bin/bash
echo "Hello Terraform! -> Installing pre-req packages here!"
apt-get update
apt-get install -y vim
echo "DONE"
EOF
}
