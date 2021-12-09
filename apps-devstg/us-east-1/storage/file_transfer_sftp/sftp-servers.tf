# -----------------------------------------------------------------------------
# sFTP Specs:
#  - Encrypted: Yes [HIPAA]
#  - Logging: Yes [HIPAA]
#  - Versioned: Yes [HIPAA]
#  - Enforce HTTPS: Yes [HIPAA]
#  - Private (ACL, Bucket Policy): Yes [HIPAA]
#  - Replicated: TBD -- For the sake of disaster recovery, still kind of easy to set up at a later time
#  - Storage Lifecycle: TBD -- For the sake of cost optimization; can be easily set up at any time but people tend to forget about it until costs reveal the mistake
#  - MFA Delete: TBD -- For the sake of data safety, but can be easily set up at any time
# -----------------------------------------------------------------------------
module "customer_sftp" {
  source        = "github.com/binbashar/terraform-aws-sftp.git?ref=1.1"
  for_each      = toset(var.customers)

  name          = "${var.project}-${var.prefix}-customer-${each.key}-files"
  iam_role_name = "sftp-logging-role"

  tags          = local.tags
}

# resource "aws_route53_record" "main" {
#   provider = aws.shared-route53

#   for_each = toset(var.customers)

#   name     = "sftp-${var.project}-${var.prefix}-customer-${each.key}.binbash.com.ar"
#   zone_id  = data.terraform_remote_state.shared-dns.aws_public_zone_id
#   type     = "CNAME"
#   ttl      = "300"
#   records  = [ # TODO: Review AWS record format here
#     "${each.key}-aws_transfer_server.main.endpoint"
#   ]
# }
