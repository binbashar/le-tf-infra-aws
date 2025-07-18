# Kinesis Data Stream for DynamoDB to S3 (Raw Bucket)
module "kinesis_stream_datalake" {
  source      = "github.com/cloudposse/terraform-aws-kinesis-stream.git?ref=0.4.0"
  stream_mode = "ON_DEMAND"
  environment = var.environment
  name        = "${var.project}-${var.environment}-ddb-lakehouse-stream"
  namespace   = var.project
}

# Kinesis Firehose Delivery Stream to S3 (Raw Bucket)
module "kinesis_firehose_datalake" {
  source = "github.com/fdmsantos/terraform-aws-kinesis-firehose.git?ref=v3.8.2"
  name   = "${var.project}-${var.environment}-ddb-lakehouse-firehose"

  # SOURCE
  input_source              = "kinesis"
  kinesis_source_stream_arn = module.kinesis_stream_datalake.stream_arn
  enable_s3_encryption      = false
  s3_kms_key_arn            = data.terraform_remote_state.keys.outputs.aws_kms_key_arn

  # DESTINATION
  destination                 = "s3"
  s3_bucket_arn               = data.terraform_remote_state.datalake_demo.outputs.s3_bucket_data_raw_arn
  s3_prefix                   = "dynamodb_data/!{partitionKeyFromQuery:tableName}/cdc_data/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/hour=!{timestamp:HH}/"
  s3_error_output_prefix      = "dynamodb_data/cdc_error/"
  s3_cross_account            = true
  enable_sse                  = false
  create_application_role     = false
  enable_dynamic_partitioning = true
  buffering_size              = 100
  buffering_interval          = 100

  # TRANSFORMATION (optional, add your lambda if needed)
  enable_lambda_transform                    = false
  dynamic_partition_metadata_extractor_query = "{tableName:.tableName}"
}


resource "aws_dynamodb_kinesis_streaming_destination" "ddb_to_kinesis" {
  stream_arn                               = module.kinesis_stream_datalake.stream_arn
  table_name                               = data.terraform_remote_state.dynamodb.outputs.dynamodb_table_name
  approximate_creation_date_time_precision = "MICROSECOND"
} 