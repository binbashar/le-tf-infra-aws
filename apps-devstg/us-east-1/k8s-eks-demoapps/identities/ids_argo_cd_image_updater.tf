#
# Argo Image Updater Roles & Policies
#
module "role_argo_cd_image_updater" {
  source = "github.com/binbashar/terraform-aws-iam.git//modules/iam-assumable-role-with-oidc?ref=v5.60.0"

  providers = {
    aws = aws.shared
  }

  create_role  = true
  role_name    = "${local.environment}-${local.prefix}-argo-cd-image-updater"
  provider_url = replace(data.terraform_remote_state.cluster.outputs.cluster_oidc_issuer_url, "https://", "")

  role_policy_arns = [
    aws_iam_policy.argo_cd_image_updater.arn
  ]
  oidc_fully_qualified_subjects = [
    "system:serviceaccount:argocd:argocd-image-updater"
  ]

  tags = local.tags_argo_image_updater
}

resource "aws_iam_policy" "argo_cd_image_updater" {
  provider    = aws.shared
  name        = "${local.environment}-${local.prefix}-argo-cd-image-updater"
  description = "Argo CD Image Updater permissions on ECR"
  tags        = local.tags_argo_image_updater
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
            "Resource": "*"
        }
    ]
}
EOF
}
