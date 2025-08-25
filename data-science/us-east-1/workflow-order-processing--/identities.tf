#======================================
# Roles & Policies: API Gateway
#======================================
module "role_apigw" {
  source = "github.com/binbashar/terraform-aws-iam.git//modules/iam-assumable-role?ref=v5.60.0"

  create_role       = true
  role_name         = "APIGatewayLambdaExecuteRole"
  role_requires_mfa = false
  trusted_role_services = [
    "apigateway.amazonaws.com"
  ]
  custom_role_policy_arns = [
    "arn:aws:iam::aws:policy/AWSXrayWriteOnlyAccess",
    module.policy_apigw.arn
  ]
}

module "policy_apigw" {
  source = "github.com/binbashar/terraform-aws-iam.git//modules/iam-policy?ref=v5.60.0"

  name        = "LambdaExecutionPolicy"
  path        = "/"
  description = "LambdaExecutionPolicy"
  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "lambda:InvokeFunction"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}
