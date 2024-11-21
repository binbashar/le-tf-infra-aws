#============================================================#
# Hosted Zone / VPC Association:
#   - Hosted Zone: app.vistapath.ai
#   - VPC: EKS VPC
#
# Ref: https://aws.amazon.com/premiumsupport/knowledge-center/private-hosted-zone-different-account/
#============================================================#

# 1. Request authorization to associate EKS VPC to the Hosted Zone (the zone's
# owner must issue this request)
resource "aws_route53_vpc_association_authorization" "with_shared_vpc" {
  provider = aws.shared

  count    = var.route53_private_zone_to_associate != null ? 1 : 0

  vpc_id  = module.vpc.vpc_id
  zone_id = var.route53_private_zone_to_associate
}

# 2. Accept the association authorization from the Hosted Zone owner account (shared)
resource "aws_route53_zone_association" "with_shared_vpc" {
  count    = var.route53_private_zone_to_associate != null ? 1 : 0

  vpc_id  = module.vpc.vpc_id
  zone_id = var.route53_private_zone_to_associate

  depends_on = [aws_route53_vpc_association_authorization.with_shared_vpc[0]]
}
