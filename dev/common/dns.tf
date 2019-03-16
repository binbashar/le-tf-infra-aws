#
# Private Hosted Zone: dev.binbash.aws (for kubernetes)
#
resource "aws_route53_zone" "dev_binbash_aws" {
    name = "dev.binbash.aws"
    vpc_id  = "${module.vpc.vpc_id}"
    
    tags = "${local.tags}"
}

resource "null_resource" "create_remote_zone_auth" {
  provisioner "local-exec" {
    command = "aws route53 create-vpc-association-authorization --profile ${var.profile} --hosted-zone-id ${aws_route53_zone.dev_binbash_aws.zone_id} --vpc VPCRegion=${var.region},VPCId=${var.shared_vpc_id}"
  }
}
