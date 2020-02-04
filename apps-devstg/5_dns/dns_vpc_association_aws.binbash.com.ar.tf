# Reference Link: https://aws.amazon.com/premiumsupport/knowledge-center/private-hosted-zone-different-account/

#============================================================#
# HOSTED ZONE: aws.binbash.com.ar from Shared to Dev Account
#============================================================#
// eg:
//aws route53 list-hosted-zones --profile ${var.profile}
//aws route53 create-vpc-association-authorization  --hosted-zone-id Z2UPXXXXXXXXX --vpc VPCRegion=us-east-1,VPCId=vpc-6812de10 --profile 'profile-host-acct'
//aws route53 list-vpc-association-authorizations   --hosted-zone-id Z2UPXXXXXXXXX                                              --profile 'profile-host-acct'
//aws route53 associate-vpc-with-hosted-zone        --hosted-zone-id Z2UPXXXXXXXXX --vpc VPCRegion=us-east-1,VPCId=vpc-6812de10 --profile 'profile-remote-acct'
//aws route53 delete-vpc-association-authorization  --hosted-zone-id Z2UPXXXXXXXXX --vpc VPCRegion=us-east-1,VPCId=vpc-6812de10 --profile 'profile-host-acct'

#
# Accept association between Dev VPC and aws.binbash.com.ar private hosted zone
#
resource "null_resource" "associate_dev_vpc_with_private_remote_hosted_zone" {
  count = var.vpc_shared_dns_assoc == true ? 1 : 0

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = "aws route53 associate-vpc-with-hosted-zone --profile ${var.profile} --hosted-zone-id ${data.terraform_remote_state.dns-shared.outputs.aws_internal_zone_id[0]} --vpc VPCRegion=${var.region},VPCId=${data.terraform_remote_state.vpc-dev.outputs.vpc_id}"
  }
}
