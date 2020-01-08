locals {
  tags = {
    Name        = "infra-vpn-pritunl"
    Terraform   = "true"
    Environment = var.environment
  }

  user_data = <<EOF
#!/bin/bash
echo "Hello Terraform! -> Installing pre-req packages here!"
apt-get update
apt-get install -y vim
echo "DONE"
EOF

}