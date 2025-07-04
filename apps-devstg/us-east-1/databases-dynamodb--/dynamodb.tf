module "dynamodb_table" {
  source = "git::https://github.com/binbashar/terraform-aws-dynamodb.git?ref=0.36.0"

  namespace                    = var.project
  stage                        = var.environment
  name                         = local.name
  hash_key                     = "id"
  autoscale_write_target       = 50
  autoscale_read_target        = 50
  autoscale_min_read_capacity  = 5
  autoscale_max_read_capacity  = 20
  autoscale_min_write_capacity = 5
  autoscale_max_write_capacity = 20
  enable_autoscaler            = true
  enable_streams               = true
  stream_view_type             = "NEW_AND_OLD_IMAGES"

  dynamodb_attributes = [
    {
      name = "id"
      type = "S"
    }
  ]

  tags = local.tags
}

# DynamoDB to Kinesis Streaming Destination
resource "aws_dynamodb_kinesis_streaming_destination" "ddb_to_kinesis" {
  stream_arn                               = module.kinesis_stream_datalake.stream_arn
  table_name                               = module.dynamodb_table.table_name
  approximate_creation_date_time_precision = "MICROSECOND"
}

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
