/*
resource "null_resource" "associate_with_remote_zone" {
    provisioner "local-exec" {
        command = "aws route53 associate-vpc-with-hosted-zone --profile ${var.profile} --hosted-zone-id ${var.dev_internal_zone_id} --vpc VPCRegion=${var.region},VPCId=${module.vpc.vpc_id}"
    }
}

resource "null_resource" "r53_to_appsprd_vpc" {
    provisioner "local-exec" {
        command = "aws route53 associate-vpc-with-hosted-zone --profile ${var.profile} --hosted-zone-id ${var.appsprd_internal_zone_id} --vpc VPCRegion=${var.region},VPCId=${module.vpc.vpc_id}"
    }
}*/
