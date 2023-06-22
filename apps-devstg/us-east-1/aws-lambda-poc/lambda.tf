resource "aws_s3_object" "initial-lambda" {

    bucket = aws_s3_bucket.lambda.bucket
    key    = "bb-lambda-test-test"
    source = "initial-lambda.zip"

}

resource "aws_lambda_function" "func" {

    depends_on = [

        aws_s3_object.initial-lambda,

    ]

    function_name = "bb-lambda-test-test"
    role          = aws_iam_role.lambda.arn
    handler       = "lambda_function.lambda_handler"
    runtime       = "python3.10"
    memory_size   = 256
    timeout       = 600

    s3_bucket = aws_s3_bucket.lambda.bucket
    s3_key    = "bb-lambda-test-test"


    environment {

      variables = local.lamba_environment_variables
    }

  lifecycle {
    ignore_changes = [
      environment,
      memory_size,
      timeout
    ]
  }

}

resource "aws_lambda_function_url" "test_latest" {
  function_name      = aws_lambda_function.func.function_name
  authorization_type = "NONE"
}
