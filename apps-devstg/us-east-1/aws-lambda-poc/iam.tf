resource "aws_iam_role" "lambda" {

    name = "bb-lambda-test-sts"

    assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF

}

resource "aws_iam_policy" "lambda" {

    name   = "bb-lambda-policy"
    policy = data.aws_iam_policy_document.lambda_policy_document.json
}


data "aws_iam_policy_document" "lambda_policy_document" {


    # ###########################################
    statement {
        sid       = "AllowS3"
        effect    = "Allow"
        resources = [
            aws_s3_bucket.lambda.arn,
            "${ aws_s3_bucket.lambda.arn }/*",
        ]

        actions = [
            "s3:*",
            "s3-object-lambda:*",
        ]
    }



}


resource "aws_iam_role_policy_attachment" "policy" {

    role       = aws_iam_role.lambda.name
    policy_arn = aws_iam_policy.lambda.arn

}
