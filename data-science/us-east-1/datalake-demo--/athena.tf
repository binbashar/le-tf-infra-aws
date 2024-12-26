# module "athena" {
#   source  = "cloudposse/athena/aws"
#   version = "v0.2.1"

#   #context = "data-lake-orders"
#   namespace = "data-lake-orders"

#   named_queries = {}
#   data_catalogs = {}
#   create_s3_bucket = false
#   create_kms_key = false
#   athena_kms_key = data.terraform_remote_state.keys.outputs.aws_kms_key_arn

#   athena_s3_bucket_id = 
#   databases = {
#     orders = {
#       create_kms_key = data.terraform_remote_state.keys.outputs.aws_kms_key_arn
#       encryption_options = "SSE_KMS"
#     }
#   }
# }

# resource "aws_athena_database" "data_lake" {
#   name   = "orders"
#   bucket = module.s3_bucket_data_processed.s3_bucket_id
#   encryption_configuration {
#     kms_key = data.terraform_remote_state.keys.outputs.aws_kms_key_arn
#     encryption_option = "SSE_KMS"
#   }
# }

module "glue_catalog_products_orders" {
  source = "github.com/binbashar/terraform-aws-glue.git//modules/glue-catalog-table?ref=0.4.0"

  catalog_table_name        = "products_orders"
  catalog_table_description = "Glue Catalog table"
  database_name             = module.glue_catalog_database.name

  storage_descriptor = {
    location = format("s3://%s/product_order_summary/", module.s3_bucket_data_processed.s3_bucket_id)
    input_format  = local.parquet_input_format
    output_format = local.parquet_output_format
    ser_de_info   = {
      serialization_library = local.parquet_serialization_library
    }
  }


}

resource "aws_athena_workgroup" "datalake-workgroup" {
  name = "datalake"

  configuration {
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = false

    result_configuration {
      output_location = "s3://${module.s3_bucket_data_processed.s3_bucket_id}/output/"

      encryption_configuration {
        encryption_option = "SSE_KMS"
        kms_key_arn       = data.terraform_remote_state.keys.outputs.aws_kms_key_arn
      }
    }
  }

  force_destroy = true
}
