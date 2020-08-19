#
# Accept Associate Shared VPC with Private Hosted Zone on DevStg
# currently for the Private HostedZone Domain: cluster-kops-1.k8s.devstg.binbash.aws
#
resource "null_resource" "associate_with_remote_zone" {
  count = var.vpc_apps_devstg_kops_dns_assoc == true ? 1 : 0

  provisioner "local-exec" {
    command = "aws route53 associate-vpc-with-hosted-zone --profile ${var.profile} --hosted-zone-id ${data.terraform_remote_state.dns-apps-devstg-kops.outputs.hosted_zone_id} --vpc VPCRegion=${var.region},VPCId=${data.terraform_remote_state.vpc-shared.outputs.vpc_id}"
  }
}
