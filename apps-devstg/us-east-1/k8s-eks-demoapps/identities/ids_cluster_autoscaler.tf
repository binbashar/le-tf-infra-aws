#
# Cluster-Autoscaler Roles & Policies
#
module "role_cluster_autoscaler" {
  source = "github.com/binbashar/terraform-aws-iam.git//modules/iam-assumable-role-with-oidc?ref=v5.60.0"

  create_role  = true
  role_name    = "${local.environment}-${local.prefix}-cluster-autoscaler"
  provider_url = replace(data.terraform_remote_state.cluster.outputs.cluster_oidc_issuer_url, "https://", "")

  role_policy_arns = [
    aws_iam_policy.cluster_autoscaler.arn
  ]
  oidc_fully_qualified_subjects = [
    "system:serviceaccount:monitoring-metrics:autoscaler-aws-cluster-autoscaler"
  ]

  tags = local.tags_cluster_autoscaler
}

resource "aws_iam_policy" "cluster_autoscaler" {
  name        = "${local.environment}-${local.prefix}-cluster-autoscaler"
  description = "Cluster Autoscaler"
  tags        = local.tags_cluster_autoscaler
  policy      = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AutoScalingDiscovery",
            "Effect": "Allow",
            "Action": [
                "autoscaling:DescribeAutoScalingGroups",
                "autoscaling:DescribeAutoScalingInstances",
                "autoscaling:DescribeLaunchConfigurations",
                "autoscaling:DescribeTags",
                "ec2:DescribeInstanceTypes",
                "ec2:DescribeLaunchTemplateVersions"
            ],
            "Resource": "*"
        },
        {
            "Sid": "AutoscalingManagement",
            "Effect": "Allow",
            "Action": [
                "autoscaling:SetDesiredCapacity",
                "autoscaling:TerminateInstanceInAutoScalingGroup",
                "ec2:DescribeInstanceTypes",
                "eks:DescribeNodegroup"
            ],
            "Resource": "*",
            "Condition": {
                "StringEquals": {
                    "autoscaling:ResourceTag/k8s.io/cluster-autoscaler/enabled": "true",
                    "autoscaling:ResourceTag/kubernetes.io/cluster/${data.terraform_remote_state.cluster.outputs.cluster_name}": "owned"
                }
            }
        }
    ]
}
EOF
}
