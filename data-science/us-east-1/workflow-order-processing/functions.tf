#======================================
# Lambda: Functions
#======================================
locals {
  functions = {
    GetOrderMetadataFunction = {
      source_path = "src/get_order_metadata_handler"
      handler     = "get_order_metadata_handler.get_order_metadata"
      environment = {
        ORDER_TABLE = module.table_order.dynamodb_table_id
      }
    }
    SNSCallbackFunction = {
      source_path = "src/sns_callback_handler"
      handler     = "sns_callback_handler.sns_callback"
      environment = {
        CALLBACK_TABLE    = module.table_callback.dynamodb_table_id
        SNS_TOPIC_ARN     = module.topic_shippingservice.topic_arn
        PAYLOAD_EVENT_KEY = "order_contents"
        TASK_TYPE         = "ORDER_SHIPPING_SERVICE"
      }
    }
    ExternalCallbackFunction = {
      source_path = "src/external_callback_handler"
      handler     = "external_callback_handler.external_callback"
      environment = {
        CALLBACK_TABLE = module.table_callback.dynamodb_table_id
      }
    }
    ProcessShippingResultFunction = {
      source_path = "src/process_shipping_result_handler"
      handler     = "process_shipping_result_handler.process_shipping_result"
      environment = {
        ORDER_TABLE             = module.table_order.dynamodb_table_id
        SHIPPING_INFO_EVENT_KEY = "shipping_info"
      }
    }
  }

  functions_common = {
    # Policy ARNs
    policies = [
      "arn:aws:iam::aws:policy/AWSXrayWriteOnlyAccess",
    ]

    # Custom policies
    policy_jsons = [
      <<-EOT
      {
        "Version": "2012-10-17",
        "Statement": [
          {
            "Sid": "lambdaRoleAPIG",
            "Effect": "Allow",
            "Action": [
              "cloudwatch:*",
              "sns:Publish",
              "dynamodb:Query",
              "dynamodb:GetItem",
              "dynamodb:PutItem",
              "dynamodb:UpdateItem"
            ],
            "Resource": ["*"]
          }
        ]
      }
      EOT
      ,
      <<-EOT
      {
        "Version": "2012-10-17",
        "Statement": [
          {
            "Sid": "StatesExecutePolicy",
            "Effect": "Allow",
            "Action": [
              "states:*"
            ],
            "Resource": ["*"]
          }
        ]
      }
      EOT
    ]
  }
}

module "functions" {
  source = "github.com/binbashar/terraform-aws-lambda.git?ref=v7.7.0"

  for_each = local.functions

  publish       = true
  function_name = each.key
  handler       = each.value.handler
  runtime       = "python3.12"
  timeout       = 30
  source_path   = each.value.source_path

  trigger_on_package_timestamp = false

  environment_variables = each.value.environment

  attach_policies    = true
  policies           = local.functions_common.policies
  number_of_policies = length(local.functions_common.policies)

  attach_policy_jsons    = true
  policy_jsons           = local.functions_common.policy_jsons
  number_of_policy_jsons = length(local.functions_common.policy_jsons)

  tags = local.tags
}
