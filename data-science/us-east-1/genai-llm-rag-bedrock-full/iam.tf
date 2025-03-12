module "iam_assumable_role_ecs_opensearch" {
  source = "github.com/binbashar/terraform-aws-iam.git//modules/iam-assumable-role?ref=v5.52.2"

  trusted_role_arns = [
    module.ecs_service.tasks_iam_role_arn
  ]


  create_role = true
  role_name   = "ecs-opensearch-serverless-access"
  role_path   = "/"

  #
  # MFA setup
  #
  role_requires_mfa    = false
  mfa_age              = 43200 # Maximum CLI/API session duration in seconds between 3600 and 43200
  max_session_duration = 3600  # Max age of valid MFA (in seconds) for roles which require MFA
  custom_role_policy_arns = [
    aws_iam_policy.ecs_opensearch_access.arn
  ]

}

resource "aws_iam_policy" "ecs_opensearch_access" {
  name        = "ecs_opensearch_access"
  description = "Allow ECS to access Opensearch"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowAccessToOpensearch",
            "Effect": "Allow",
            "Action": [
                "aoss:*"
            ],
            "Resource": [
                "${aws_opensearchserverless_collection.this.arn}"
            ]
        }
    ]
}
      
EOF
}
