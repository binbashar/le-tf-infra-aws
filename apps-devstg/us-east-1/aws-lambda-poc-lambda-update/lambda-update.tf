resource "aws_s3_object" "initial-lambda" {

    bucket = "bb-lambda-test"
    key    = "bb-lambda-test-test-update/updated-lambda.zip"
    source = "updated-lambda.zip"
    etag   = filebase64sha256("updated-lambda.zip")

}

resource "aws_lambda_function" "func" {

    depends_on = [ aws_s3_object.initial-lambda ]

    function_name = "bb-lambda-test-test"
    handler       = "lambda_function.lambda_handler"
    runtime       = "python3.10"

    role             = "arn:aws:iam::523857393444:role/bb-lambda-test-sts"
    source_code_hash = filebase64sha256("updated-lambda.zip")
    publish          = true
    timeout          = 60
    memory_size      = 128

    s3_bucket = "bb-lambda-test"
    s3_key    = "bb-lambda-test-test-update/updated-lambda.zip"


    environment {

      variables = local.lamba_environment_variables

    }

}
