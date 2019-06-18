#Reference Link: https://aws.amazon.com/premiumsupport/knowledge-center/private-hosted-zone-different-account/

#============================================================#
# HOSTED ZONE: aws.binbash.com.ar from Shared to Dev Account
#============================================================#
// eg:
//aws route53 list-hosted-zones --profile ${var.profile}
//aws route53 create-vpc-association-authorization  --hosted-zone-id Z2UPXXXXXXXXX --vpc VPCRegion=us-east-1,VPCId=vpc-6812de10 --profile 'profile-host-acct'
//aws route53 list-vpc-association-authorizations   --hosted-zone-id Z2UPXXXXXXXXX                                              --profile 'profile-host-acct'
//aws route53 associate-vpc-with-hosted-zone        --hosted-zone-id Z2UPXXXXXXXXX --vpc VPCRegion=us-east-1,VPCId=vpc-6812de10 --profile 'profile-remote-acct'
//aws route53 delete-vpc-association-authorization  --hosted-zone-id Z2UPXXXXXXXXX --vpc VPCRegion=us-east-1,VPCId=vpc-6812de10 --profile 'profile-host-acct'

resource "null_resource" "associate_vpc_with_private_remote_hosted_zone" {
  provisioner "local-exec" {
    command = "aws route53 associate-vpc-with-hosted-zone --hosted-zone-id ${var.shared_aws_internal_zone_id} --vpc VPCRegion=${var.region},VPCId=${module.vpc.vpc_id} --profile ${var.profile}"
  }
}
