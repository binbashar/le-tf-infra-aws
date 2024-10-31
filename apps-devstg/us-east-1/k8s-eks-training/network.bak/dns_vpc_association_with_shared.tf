#============================================================#
# Hosted Zone / VPC Association:
#   - Hosted Zone: aws.binbash.com.ar
#   - VPC: EKS VPC
#
# Ref: https://aws.amazon.com/premiumsupport/knowledge-center/private-hosted-zone-different-account/
#============================================================#

# 1. Request authorization to associate EKS VPC to the Hosted Zone (the zone's
# owner must issue this request)
resource "aws_route53_vpc_association_authorization" "with_shared_vpc" {
  provider = aws.shared

  vpc_id  = module.vpc-eks.vpc_id
  zone_id = data.terraform_remote_state.shared-dns.outputs.aws_internal_zone_id
}

# 2. Accept the association authorization from the Hosted Zone owner account (shared)
resource "aws_route53_zone_association" "with_shared_vpc" {
  vpc_id  = module.vpc-eks.vpc_id
  zone_id = data.terraform_remote_state.shared-dns.outputs.aws_internal_zone_id

  depends_on = [aws_route53_vpc_association_authorization.with_shared_vpc]
}
