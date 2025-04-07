locals {
  parquet_input_format          = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat"
  parquet_output_format         = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat"
  parquet_serialization_library = "org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe"
}


################################################################
# Create Role used by the Glue Job.                            #
################################################################

module "iam_role" {
  source = "github.com/binbashar/terraform-aws-iam.git//modules/iam-assumable-role?ref=v5.52.2"

  create_role = true
  role_name   = "glue-script"

  create_custom_role_trust_policy = true
  custom_role_trust_policy        = data.aws_iam_policy_document.glue_assume_role.json

  custom_role_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole",
    "arn:aws:iam::aws:policy/AmazonS3FullAccess", #TODO: restrict
  ]

  inline_policy_statements = [{
    sid    = "KMSAccess"
    effect = "Allow"
    actions = [
      "kms:*", #TODO: restrict
    ]
    resources = [
      "*"
    ]
  }]

  role_description = "Role for AWS Glue with access to EC2, S3, and Cloudwatch Logs"

}

data "aws_iam_policy_document" "glue_assume_role" {

  statement {
    sid    = "AllowGlueAssumeThisRole"
    effect = "Allow"

    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type        = "Service"
      identifiers = ["glue.amazonaws.com"]
    }
  }
}

#################################################################################
# Create a Glue job that will run the script located in the S3 bucket.          #
# The script is in the 'config' directory and has been uploaded to the bucket.  #
#################################################################################

module "glue_job" {
  source = "github.com/binbashar/terraform-aws-glue.git//modules/glue-job?ref=0.4.0"

  job_name          = "${local.name}-glue-job"
  job_description   = "Glue Job that runs Python script"
  role_arn          = module.iam_role.iam_role_arn
  glue_version      = "4.0"
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



##########################################
# Create the catalog database in Glue.   #
##########################################


module "glue_catalog_database" {
  source = "github.com/binbashar/terraform-aws-glue.git//modules/glue-catalog-database?ref=0.4.0"

  catalog_database_name        = "sales"
  catalog_database_description = "Glue Catalog database for the data located in the Data source"
}


#################################################################################
# Create the catalog tables: products, orders and product_orders.               #
#  products       = mysql -> DMS -> S3                                          #
#  orders         = postgres -> DMS -> S3                                       #
#  product_orders = S3(products) + S3(orders) -> Glue Job -> S3                 #
#################################################################################


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
}

module "glue_catalog_products_orders" {
  source = "github.com/binbashar/terraform-aws-glue.git//modules/glue-catalog-table?ref=0.4.0"

  catalog_table_name        = "products_orders"
  catalog_table_description = "Glue Catalog table"
  database_name             = module.glue_catalog_database.name

  storage_descriptor = {
    location      = format("s3://%s/product_order_summary/", module.s3_bucket_data_processed.s3_bucket_id)
    input_format  = local.parquet_input_format
    output_format = local.parquet_output_format
    ser_de_info = {
      serialization_library = local.parquet_serialization_library
    }
  }
}

###########################################################################################################
# Crawls the metadata from the S3 bucket and puts the results into a database in the Glue Data Catalog.   #
# The crawler will read the first 2 MB of data from that file, and recognize the schema.                  #
###########################################################################################################
module "glue_crawler" {
  source = "github.com/binbashar/terraform-aws-glue.git//modules/glue-crawler?ref=0.4.0"

  crawler_name        = "${local.name}-crawler"
  crawler_description = "Glue crawler that processes data in the source bucket and writes the metadata into a Glue Catalog database"
  database_name       = module.glue_catalog_database.name
  role                = module.iam_role.iam_role_arn

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


##################################################
# Create trigger: Run crawler at 5:00 everyday.  #
##################################################

module "glue_trigger" {
  source = "github.com/binbashar/terraform-aws-glue.git//modules/glue-trigger?ref=0.4.0"

  trigger_name      = "${local.name}-glue-trigger"
  type              = "SCHEDULED"
  schedule          = "cron(0 5 * * ? *)"
  start_on_creation = true
  actions = [{
    crawler_name = module.glue_crawler.name
  }]

}


#####################################################################
# Create trigger: Run the glue job once the crawler has succeeded.  #
#####################################################################

module "glue_trigger_job_after_crawler" {
  source = "github.com/binbashar/terraform-aws-glue.git//modules/glue-trigger?ref=0.4.0"

  trigger_name      = "${local.name}-glue-job-trigger-on-demand"
  type              = "CONDITIONAL"
  start_on_creation = true
  actions = [{
    job_name = module.glue_job.name
  }]

  predicate = {
    conditions = [{
      crawler_name = module.glue_crawler.name
      crawl_state  = "SUCCEEDED"
    }]
  }
}


##############################################################################################################################
# Create trigger: This is for demo purposes. Run an 'on_demand' crawler.                                                     #
# Since the trigger 'glue_trigger_job_after_crawler' is created, the glue job will run after this crawler succeeds:          #
# 1- Run this crawler 'on_demand'.                                                                                           #
# 2- Run the glue job due to the trigger condition in 'glue_trigger_job_after_crawler'.                                      #
# We run this crawler 'on_demand' to execute both the Glue job and the crawler immediately after creating these resources,   #
# without waiting for the next scheduled run.                                                                                #
##############################################################################################################################

module "glue_trigger_crawler_on_demand" {
  source = "github.com/binbashar/terraform-aws-glue.git//modules/glue-trigger?ref=0.4.0"

  trigger_name      = "${local.name}-glue-trigger-crawler-on-demand"
  type              = "ON_DEMAND"
  start_on_creation = true
  actions = [{
    crawler_name = module.glue_crawler.name
  }]

}


###########################################################################
# Create  the S3 bucket to store the python script used by the glue job.  #
###########################################################################

module "s3_bucket_glue_script_storage" {
  source = "github.com/binbashar/terraform-aws-s3-bucket.git?ref=v4.2.1"

  bucket        = "${local.name}-glue-script"
  acl           = null
  force_destroy = true

  attach_policy = false

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


###################################################
# Upload the python script used by the glue job.  #
###################################################

resource "aws_s3_object" "job_script" {
  bucket = module.s3_bucket_glue_script_storage.s3_bucket_id
  key    = "etl_script.py"
  source = "${path.module}/config/etl_script.py"
  tags   = local.tags
}

resource "aws_lakeformation_permissions" "products_orders" {

  principal   = module.iam_role.iam_role_arn
  permissions = ["ALL"]

  table {
    database_name = module.glue_catalog_database.name
    name = module.glue_catalog_products_orders.name
  }
}

resource "aws_lakeformation_permissions" "orders" {

  principal   = module.iam_role.iam_role_arn
  permissions = ["ALL"]

  table {
    database_name = module.glue_catalog_database.name
    name = module.glue_catalog_orders.name
  }
}

resource "aws_lakeformation_permissions" "products" {

  principal   = module.iam_role.iam_role_arn
  permissions = ["ALL"]

  table {
    database_name = module.glue_catalog_database.name
    name = module.glue_catalog_products.name
  }
}