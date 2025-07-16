locals {
  aws_oidc_github_issuer_url   = "https://token.actions.githubusercontent.com"
  github_oidc_allowed_branches = "repo:binbashar/le-genai-ml-clients:*"
}

resource "aws_iam_openid_connect_provider" "aws_github_oidc" {
  url = local.aws_oidc_github_issuer_url

  client_id_list = [
    "sts.amazonaws.com",
  ]

  # Obtained from the certificate of the url, see here for more details https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_oidc_verify-thumbprint.html
  # Alternatively this can also be obtained by the aws managagement console when creading an oidc provider and use the "Get Thumbprint button"
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1", "1c58a3a8518e8759bf075b76b750d4f2df264fcd", "f879abce0008e4eb126e0097e46620f5aaae26ad"]
}

resource "aws_iam_role" "github_actions_role" {
  name               = "${local.name}-github-actions-oidc"
  description        = "Github OIDC integration for Github Actions"
  tags               = merge(local.tags, { Name = "github-oidc-workflows" })
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "GithubActionsAssumeRoleWithIdp",
      "Effect": "Allow",
      "Action": [
        "sts:AssumeRoleWithWebIdentity"
      ],
      "Principal": {
        "Federated": "${aws_iam_openid_connect_provider.aws_github_oidc.arn}"
      },
      "Condition": {
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "${local.github_oidc_allowed_branches}",
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        }
      }
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "github_actions_oidc" {
  role       = aws_iam_role.github_actions_role.name
  policy_arn = aws_iam_policy.github_actions_oidc.arn
}

resource "aws_iam_policy" "github_actions_oidc" {
  name        = "${local.name}-github-actions-oidc"
  description = "Github OIDC integration for Github Actions"
  tags        = merge(local.tags, { Name = "github-oidc-workflows" })
  policy      = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowLogin",
            "Effect": "Allow",
            "Action": [
                "ecr:GetAuthorizationToken"
            ],
            "Resource": "*"
        },
        {
            "Sid": "AllowList",
            "Effect": "Allow",
            "Action": [
                "ecr:DescribeRepositories"
            ],
            "Resource": "arn:aws:ecr:${var.region}:${var.accounts.data-science.id}:repository/*"
        },
        {
            "Sid": "AllowPush",
            "Effect": "Allow",
            "Action": [
                "ecr:GetDownloadUrlForLayer",
                "ecr:BatchGetImage",
                "ecr:BatchCheckLayerAvailability",
                "ecr:PutImage",
                "ecr:InitiateLayerUpload",
                "ecr:UploadLayerPart",
                "ecr:CompleteLayerUpload",
                "ecr:ListImages",
                "ecr:DescribeImages"
            ],
            "Resource": "${module.ecr_repositories.repository_arn}"
        }
    ]
}
EOF
}