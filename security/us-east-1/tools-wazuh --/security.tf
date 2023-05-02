resource "aws_iam_instance_profile" "wazuh" {
  name = "Wazuh"
  role = aws_iam_role.wazuh.name
}

resource "aws_iam_role" "wazuh" {
  name = "Wazuh"
  path = "/"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

data "aws_iam_policy_document" "wazuh" {
  statement {
    sid      = "ReadCloudTrailBucket"
    effect   = "Allow"
    actions  = [
      "s3:GetObject",
      "s3:ListBucket",
    ]
    resources = [
      "arn:aws:s3:::bb-security-cloudtrail-org/*",
      "arn:aws:s3:::bb-security-cloudtrail-org"
    ]
  }

  statement {
    sid      = "UseKmsDefaultKey"
    effect   = "Allow"
    actions  = [
      "kms:GenerateDataKey*",
      "kms:Decrypt*",
    ]
    resources = [
      data.terraform_remote_state.keys.outputs.aws_kms_key_arn,
    ]
  }
}

resource "aws_iam_policy" "wazuh" {
  name        = "Wazuh"
  description = "Wazuh Permissions"

  policy = data.aws_iam_policy_document.wazuh.json
}

resource "aws_iam_role_policy_attachment" "wazuh" {
  role       = aws_iam_role.wazuh.name
  policy_arn = aws_iam_policy.wazuh.arn
}

resource "aws_iam_role_policy_attachment" "connect_via_ssm" {
  role       = aws_iam_role.wazuh.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
