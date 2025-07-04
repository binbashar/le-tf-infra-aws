# # Kinesis Firehose Delivery Stream to S3 (Raw Bucket)
# module "kinesis_firehose_datalake" {
#   source = "github.com/fdmsantos/terraform-aws-kinesis-firehose.git?ref=v3.8.2"
#   name   = "${var.project}-${var.environment}-ddb-lakehouse-firehose"

#   # SOURCE
#   input_source              = "kinesis"
#   kinesis_source_stream_arn = data.terraform_remote_state.kinesis_stream_apps_devstg.outputs.kinesis_stream_arn
#   enable_s3_encryption      = true
#   s3_kms_key_arn            = data.terraform_remote_state.keys.outputs.aws_kms_key_arn

#   # DESTINATION
#   destination                 = "s3"
#   s3_bucket_arn               = module.s3_bucket_data_raw.s3_bucket_arn
#   s3_prefix                   = "dynamodb_data/!{partitionKeyFromQuery:tableName}/cdc_data/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/hour=!{timestamp:HH}/"
#   s3_error_output_prefix      = "dynamodb_data/cdc_error/"
#   s3_cross_account            = false
#   enable_sse                  = true
#   create_application_role     = false
#   enable_dynamic_partitioning = true
#   buffering_size              = 100
#   buffering_interval          = 100

#   # TRANSFORMATION (optional, add your lambda if needed)
#   enable_lambda_transform = false
#   # transform_lambda_arn  = module.lambda_function_ddb_stream_converter.lambda_function_arn
#   dynamic_partition_metadata_extractor_query = "{tableName:.tableName}"
# }

