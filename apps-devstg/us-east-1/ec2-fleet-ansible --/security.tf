#
# EC2 Profile (IAM Role)
#
resource "aws_iam_instance_profile" "basic_instance" {
  count = var.instance_profile == "true" ? 1 : 0

  name = "basic-instance-profile-${var.prefix}-${var.name}"
  role = aws_iam_role.basic_instance_assume_role[0].name
}

resource "aws_iam_role" "basic_instance_assume_role" {
  count = var.instance_profile == "true" ? 1 : 0

  name               = "basic-instance-role-${var.prefix}-${var.name}"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.this.json
}

data "aws_iam_policy_document" "this" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

#
# Attach AWS IAM SSM Managed Policy
#
resource "aws_iam_role_policy_attachment" "ec2_ssm_access" {
  count = var.enable_ssm_access == true ? 1 : 0

  role       = aws_iam_role.basic_instance_assume_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
