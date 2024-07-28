#======================================
# DynamoDB: Tables
#======================================

module "table_order" {
  source = "github.com/terraform-aws-modules/terraform-aws-dynamodb-table.git?ref=v4.0.1"

  name           = "OrderTable"
  table_class    = "STANDARD"
  billing_mode   = "PROVISIONED"
  read_capacity  = 1
  write_capacity = 1
  hash_key       = "order_id"
  attributes     = [
    {
      name = "order_id"
      type = "S"
    },
  ]

  deletion_protection_enabled = false

  tags = local.tags
}

module "table_callback" {
  source = "github.com/terraform-aws-modules/terraform-aws-dynamodb-table.git?ref=v4.0.1"

  name           = "CallbackTable"
  table_class    = "STANDARD"
  billing_mode   = "PROVISIONED"
  read_capacity  = 1
  write_capacity = 1
  hash_key       = "order_id"
  range_key      = "task_type"
  attributes     = [
    {
      name = "order_id"
      type = "S"
    },
    {
      name = "task_type"
      type = "S"
    },
  ]

  deletion_protection_enabled = false

  tags = local.tags
}
