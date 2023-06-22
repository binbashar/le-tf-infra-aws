resource "aws_s3_bucket" "lambda" {

    bucket        = "bb-lambda-test"
    force_destroy = true
    tags          = local.tags
    tags_all      = local.tags

}
