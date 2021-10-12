#
# Cluster Autoscaler
#
resource "aws_iam_policy" "demoapps_cluster_autoscaler" {
  name        = "demoapps-cluster-autoscaler"
  description = "DemoApps Cluster Autoscaler"
  policy      = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "EksWorkerAutoscalingAll",
            "Effect": "Allow",
            "Action": [
                "autoscaling:DescribeAutoScalingGroups",
                "autoscaling:DescribeAutoScalingInstances",
                "autoscaling:DescribeLaunchConfigurations",
                "autoscaling:DescribeTags",
                "ec2:DescribeLaunchTemplateVersions"
            ],
            "Resource": "*"
        },
        {
            "Sid": "EksWorkerAutoscalingOwn",
            "Effect": "Allow",
            "Action": [
                "autoscaling:SetDesiredCapacity",
                "autoscaling:TerminateInstanceInAutoScalingGroup",
                "autoscaling:UpdateAutoScalingGroup"
            ],
            "Resource": "*",
            "Condition": {
                "StringEquals": {
                    "autoscaling:ResourceTag/k8s.io/cluster-autoscaler/enabled": "true",
                    "autoscaling:ResourceTag/kubernetes.io/cluster/${data.terraform_remote_state.apps-devstg-eks-demoapps-cluster.outputs.cluster_name}": "owned"
                }
            }
        }
    ]
}
EOF
}
