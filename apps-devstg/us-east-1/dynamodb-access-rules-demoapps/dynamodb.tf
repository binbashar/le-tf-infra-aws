module "dynamodb_table" {
  source = "git::https://github.com/binbashar/terraform-aws-dynamodb.git?ref=v0.37.0"

  namespace                    = var.project
  stage                        = var.environment
  name                         = local.dbname
  hash_key                     = "PK"
  range_key                    = "SK"
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
      name = "PK"
      type = "S"
    },
    {
      name = "SK"
      type = "S"
    },
    {
      name = "GSI1PK"
      type = "S"
    },

    {
      name = "GSI1SK"
      type = "S"
    }
  ]

  global_secondary_index_map = [
    {
      name            = "GSI1"
      hash_key        = "GSI1PK"
      range_key       = "GSI1SK"
      projection_type = "ALL"
    }
  ]

  tags = local.tags
}
