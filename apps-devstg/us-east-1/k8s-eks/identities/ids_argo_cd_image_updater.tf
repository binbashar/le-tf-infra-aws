#
# ArgoCD Image Updater Roles & Policies
#
module "role_argo_cd_image_updater" {
  source = "github.com/binbashar/terraform-aws-iam.git//modules/iam-assumable-role-with-oidc?ref=v5.2.0"

  providers = {
    aws = aws.shared
  }

  create_role  = true
  role_name    = "${local.environment}-argo-cd-image-updater"
  provider_url = replace(data.terraform_remote_state.eks-cluster.outputs.cluster_oidc_issuer_url, "https://", "")

  role_policy_arns = [
    aws_iam_policy.argo_cd_image_updater.arn
  ]
  oidc_fully_qualified_subjects = [
    "system:serviceaccount:argo-cd-image-updater:argo-cd-image-updater"
  ]

  tags = local.tags_argo_cd_image_updater
}

resource "aws_iam_policy" "argo_cd_image_updater" {
  provider    = aws.shared
  name        = "${local.environment}-argo-cd-image-updater"
  description = "ArgoCD Image Updater permissions on ECR"
  tags        = local.tags_argo_cd_image_updater
  policy      = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ecr:GetAuthorizationToken",
                "ecr:BatchCheckLayerAvailability",
                "ecr:GetDownloadUrlForLayer",
                "ecr:GetRepositoryPolicy",
                "ecr:DescribeRepositories",
                "ecr:ListImages",
                "ecr:DescribeImages",
                "ecr:BatchGetImage",
                "ecr:GetLifecyclePolicy",
                "ecr:GetLifecyclePolicyPreview",
                "ecr:ListTagsForResource",
                "ecr:DescribeImageScanFindings"
            ],
            "Resource": [
              "${data.terraform_remote_state.shared-container-registry.outputs.repository_arn}/*"
            ]
        }
    ]
}
EOF
}
