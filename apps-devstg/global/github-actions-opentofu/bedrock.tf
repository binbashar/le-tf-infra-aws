data "aws_iam_policy_document" "github_actions_opentofu_bedrock" {
  statement {
    sid       = "InvokeSelectedInferenceProfile"
    effect    = "Allow"
    actions   = ["bedrock:InvokeModel"]
    resources = [local.bedrock_inference_profile_arn]
  }

  statement {
    sid       = "ReadSelectedInferenceProfile"
    effect    = "Allow"
    actions   = ["bedrock:GetInferenceProfile"]
    resources = [local.bedrock_inference_profile_arn]
  }

  statement {
    sid       = "InvokeProfileDestinationModelsOnly"
    effect    = "Allow"
    actions   = ["bedrock:InvokeModel"]
    resources = local.bedrock_foundation_model_arns

    condition {
      test     = "StringLike"
      variable = "bedrock:InferenceProfileArn"
      values   = [local.bedrock_inference_profile_arn]
    }
  }
}

resource "aws_iam_policy" "github_actions_opentofu_bedrock" {
  name        = local.github_actions_opentofu_bedrock_policy_name
  description = "Invoke-only access to the selected Bedrock inference profile"
  policy      = data.aws_iam_policy_document.github_actions_opentofu_bedrock.json
}

resource "aws_iam_role_policy_attachment" "github_actions_opentofu_bedrock" {
  role       = aws_iam_role.github_actions_opentofu_bedrock.name
  policy_arn = aws_iam_policy.github_actions_opentofu_bedrock.arn
}
