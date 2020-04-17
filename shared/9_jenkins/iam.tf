#
# The following policy fulfills the requirement of the Ansible Certbot role that
# takes care of creating and renewing LetsEncrypt certificates.
#
resource "aws_iam_policy" "jenkins_master" {
  name        = "jenkins-master"
  description = "Access policy for Jenkins Master"
  policy      = data.aws_iam_policy_document.jenkins_master.json
}

data "aws_iam_policy_document" "jenkins_master" {
  statement {
    actions = [
      "route53:ListHostedZones",
      "route53:GetChange"
    ]
    resources = ["*"]
  }
  
  statement {
    actions = [
      "route53:ChangeResourceRecordSets"
    ]
    resources = [
      "arn:aws:route53:::hostedzone/${data.terraform_remote_state.dns.outputs.aws_public_zone_id[0]}"
    ]
  }
}