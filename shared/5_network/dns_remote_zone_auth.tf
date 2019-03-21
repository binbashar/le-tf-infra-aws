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


resource "null_resource" "dns_private_hosted_zone_reate_vpc_association_auth" {
    provisioner "local-exec" {
        command = "aws route53 create-vpc-association-authorization --hosted-zone-id ${var.dev_internal_zone_id} --vpc VPCRegion=${var.region},VPCId=${var.dev_vpc_id} --profile ${var.profile}"
    }
}
