locals {
  parquet_input_format          = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat"
  parquet_output_format         = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat"
  parquet_serialization_library = "org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe"
}

module "iam_role" {
  source  = "cloudposse/iam-role/aws"
  version = "0.20.0"

  enabled   = true
  namespace = "glue-script"

  principals = {
    "Service" = ["glue.amazonaws.com"]
  }

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole",
    "arn:aws:iam::aws:policy/AmazonS3FullAccess" #TODO: restrict
  ]

  policy_document_count = 1
  policy_documents = [
    join("", data.aws_iam_policy_document.kms.*.json),
  ]
  policy_description = "Policy for AWS Glue with access to EC2, S3, and Cloudwatch Logs"
  role_description   = "Role for AWS Glue with access to EC2, S3, and Cloudwatch Logs"

}

data "aws_iam_policy_document" "kms" {

  statement {
    sid    = "BaseAccess"
    effect = "Allow"

    actions = [
      "kms:*",
    ]

    resources = [
      "*"
    ]
  }
}

module "glue_job" {
  source = "github.com/binbashar/terraform-aws-glue.git//modules/glue-job?ref=0.4.0"

  job_name          = "${local.name}-glue-job"
  job_description   = "Glue Job that runs Python script"
  role_arn          = module.iam_role.arn
  glue_version      = "5.0"
  worker_type       = "Standard"
  number_of_workers = 2
  max_retries       = 0

  # The job timeout in minutes
  timeout = 20

  command = {
    # The name of the job command. Defaults to `glueetl`.
    # Use `pythonshell` for Python Shell Job Type, or `gluestreaming` for Streaming Job Type.
    name            = "glueetl"
    script_location = format("s3://%s/etl_script.py", module.s3_bucket_glue_script_storage.s3_bucket_id)
    python_version  = 3
  }

}

module "glue_catalog_database" {
  source = "github.com/binbashar/terraform-aws-glue.git//modules/glue-catalog-database?ref=0.4.0"

  catalog_database_name        = "sales"
  catalog_database_description = "Glue Catalog database for the data located in the Data source"
  # location_uri                 = local.data_source

  # context = module.this.context
}

module "glue_catalog_products" {
  source = "github.com/binbashar/terraform-aws-glue.git//modules/glue-catalog-table?ref=0.4.0"

  catalog_table_name        = "products"
  catalog_table_description = "Users Glue Catalog table"
  database_name             = module.glue_catalog_database.name

  storage_descriptor = {
    location      = format("s3://%s/destinationdata/demoapps/sockshop_products/", module.s3_bucket_data_raw.s3_bucket_id)
    input_format  = local.parquet_input_format
    output_format = local.parquet_output_format
    ser_de_info = {
      serialization_library = local.parquet_serialization_library
    }
  }

  #partition_keys = var.glue_catalog_table_partition_keys

}

module "glue_catalog_orders" {
  source = "github.com/binbashar/terraform-aws-glue.git//modules/glue-catalog-table?ref=0.4.0"

  catalog_table_name        = "orders"
  catalog_table_description = "Orders Glue Catalog table"
  database_name             = module.glue_catalog_database.name

  storage_descriptor = {
    location      = format("s3://%s/destinationdata/public/sockshop_orders/", module.s3_bucket_data_raw.s3_bucket_id)
    input_format  = local.parquet_input_format
    output_format = local.parquet_output_format
    ser_de_info = {
      serialization_library = local.parquet_serialization_library
    }
  }

  #partition_keys = var.glue_catalog_table_partition_keys

}

resource "aws_lakeformation_permissions" "default" {

  principal   = module.iam_role.arn
  permissions = ["ALL"]

  database {
    name = module.glue_catalog_database.name
    #name          = module.glue_catalog_table.name
  }
}

# Crawls the data in the S3 bucket and puts the results into a database in the Glue Data Catalog.
# The crawler will read the first 2 MB of data from that file, and recognize the schema.
# After that, the crawler will sync the table `medicare` in the Glue database.
module "glue_crawler" {
  source = "github.com/binbashar/terraform-aws-glue.git//modules/glue-crawler?ref=0.4.0"

  crawler_name        = "${local.name}-crawler"
  crawler_description = "Glue crawler that processes data in  the source bucket and writes the metadata into a Glue Catalog database"
  database_name       = module.glue_catalog_database.name
  role                = module.iam_role.arn
  schedule            = "cron(0 1 * * ? *)"

  schema_change_policy = {
    delete_behavior = "LOG"
    update_behavior = null
  }

  catalog_target = [
    {
      database_name = module.glue_catalog_database.name
      tables        = [module.glue_catalog_orders.name, module.glue_catalog_products.name, module.glue_catalog_products_orders.name]
    }
  ]

  depends_on = [
    aws_lakeformation_permissions.default
  ]
}


module "s3_bucket_glue_script_storage" {
  source = "github.com/binbashar/terraform-aws-s3-bucket.git?ref=v4.2.1"

  bucket        = "${local.name}-glue-script"
  acl           = null
  force_destroy = true

  attach_policy = false
  #policy        = data.aws_iam_policy_document.bucket_policy.json

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        kms_master_key_id = data.terraform_remote_state.keys.outputs.aws_kms_key_arn
        sse_algorithm     = "aws:kms"
      }
    }
  }

  lifecycle_rule = [
    {
      id      = "billing-objects"
      enabled = true
      prefix  = ""

      tags = {
        rule      = "log"
        autoclean = "true"
      }

      transition = [
        {
          days          = 90
          storage_class = "ONEZONE_IA"
        },
        {
          days          = 365
          storage_class = "GLACIER"
        }
      ]

      expiration = {
        days = 1825
        # 5 years
      }

      noncurrent_version_expiration = {
        days = 1095
        # 2 years
      }
    },
  ]

  # S3 bucket-level Public Access Block configuration
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  tags = local.tags
}

resource "aws_s3_object" "job_script" {

  bucket = module.s3_bucket_glue_script_storage.s3_bucket_id
  key    = "etl_script.py"
  source = "${path.module}/config/etl_script.py"
  tags   = local.tags
}


