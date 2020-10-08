#
# DNS/VPC association between Apps DevStg VPC and aws.binbash.com.ar
#

# Authorize association from the owner account of the Private Zone
resource "aws_route53_vpc_association_authorization" "with_apps_devstg_vpc" {
  vpc_id  = data.terraform_remote_state.vpc-apps-devstg.outputs.vpc_id
  zone_id = aws_route53_zone.aws_private_hosted_zone_1.zone_id
}

# Complete the association from the owner account of the VPC
resource "aws_route53_zone_association" "with_apps_devstg_vpc" {
  provider = aws.apps-devstg

  vpc_id  = aws_route53_vpc_association_authorization.with_apps_devstg_vpc.vpc_id
  zone_id = aws_route53_vpc_association_authorization.with_apps_devstg_vpc.zone_id
}


#
# DNS/VPC association between Apps DevStg EKS VPC and aws.binbash.com.ar
#

# Authorize association from the owner account of the Private Zone
resource "aws_route53_vpc_association_authorization" "with_apps_devstg_eks_vpc" {
  vpc_id  = data.terraform_remote_state.vpc-apps-devstg-eks.outputs.vpc_id
  zone_id = aws_route53_zone.aws_private_hosted_zone_1.zone_id
}

# Complete the association from the owner account of the VPC
resource "aws_route53_zone_association" "with_apps_devstg_eks_vpc" {
  provider = aws.apps-devstg

  vpc_id  = aws_route53_vpc_association_authorization.with_apps_devstg_eks_vpc.vpc_id
  zone_id = aws_route53_vpc_association_authorization.with_apps_devstg_eks_vpc.zone_id
}


#
# DNS/VPC association between Apps Prd VPC and aws.binbash.com.ar
#

# Authorize association from the owner account of the Private Zone
resource "aws_route53_vpc_association_authorization" "with_apps_prd_vpc" {
  vpc_id  = data.terraform_remote_state.vpc-apps-prd.outputs.vpc_id
  zone_id = aws_route53_zone.aws_private_hosted_zone_1.zone_id
}

# Complete the association from the owner account of the VPC
resource "aws_route53_zone_association" "with_apps_prd_vpc" {
  provider = aws.apps-prd

  vpc_id  = aws_route53_vpc_association_authorization.with_apps_prd_vpc.vpc_id
  zone_id = aws_route53_vpc_association_authorization.with_apps_prd_vpc.zone_id
}
