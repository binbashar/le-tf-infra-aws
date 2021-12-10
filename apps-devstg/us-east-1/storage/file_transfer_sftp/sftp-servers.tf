# -----------------------------------------------------------------------------
# sFTP Specs:

# -----------------------------------------------------------------------------
# Creates a sFTP server
# TODO: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/transfer_server
#       * Add VPC capabilities
#       * Add the new security policy 2020-06
#       * Add RSA private key host key
#       * Add endpoint output to module
module "customer_sftp" {
  source   = "github.com/binbashar/terraform-aws-sftp.git?ref=1.1"

  name          = "${var.project}-${var.prefix}-customer-files"
  iam_role_name = "sftp-logging-role"

  tags = local.tags
}

resource "aws_route53_record" "main" {
  provider = aws.shared-route53

  for_each = var.customers

  name     = "sftp-${var.project}-${var.prefix}-customer-${each.value["username"]}.binbash.com.ar" # Review wording
  zone_id  = data.terraform_remote_state.shared-dns.outputs.aws_internal_zone_id[0]
  type     = "CNAME"
  ttl      = "300"
  records  = [ # TODO: Review AWS record format here
    "${module.customer_sftp.sftp_server_id}.server.transfer.us-east-1.amazonaws.com."
  ]
}
