#======================================
# Step Functions: Order and Shipping
#======================================

module "workflow" {
  source = "github.com/terraform-aws-modules/terraform-aws-step-functions.git?ref=v4.2.1"

  publish = true
  name    = "CallbackExampleWorkflow"

  definition = <<EOF
{
  "StartAt": "Get Order Metadata",
  "States": {
    "Get Order Metadata": {
      "Type": "Task",
      "Resource": "${module.functions["GetOrderMetadataFunction"].lambda_function_arn}",
      "ResultPath": "$.order_contents",
      "Next": "Shipping Service Callback"
    },
    "Shipping Service Callback": {
      "Type": "Task",
      "Resource": "arn:aws:states:::lambda:invoke.waitForTaskToken",
      "Parameters": {
        "FunctionName": "${module.functions["SNSCallbackFunction"].lambda_function_arn}",
        "Payload": {
          "token.$": "$$.Task.Token",
          "input.$": "$",
          "callback": "true"
        }
      },
      "ResultPath": "$.shipping_info",
      "Next": "Process Shipping Results"
    },
    "Process Shipping Results": {
      "Type": "Task",
      "Resource": "${module.functions["ProcessShippingResultFunction"].lambda_function_arn}",
      "ResultPath": "$",
      "End": true
    }
  }
}
EOF

  # TODO Consider using service integrations rather than roles/policies
  # service_integrations = {
  #   lambda = {
  #     lambda = [
  #     module.lambda_function.lambda_function_arn, "arn:aws:lambda:eu-west-1:123456789012:function:test2"]
  #   }
  # }

  # Additional policies
  attach_policy_json = true
  policy_json        = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "lambda:InvokeFunction"
            ],
            "Resource": ["*"]
        }
    ]
}
EOF

  attach_policies = true
  policies = [
    "arn:aws:iam::aws:policy/AWSXrayWriteOnlyAccess",
    "arn:aws:iam::aws:policy/CloudWatchEventsFullAccess",
  ]
  number_of_policies = 2

  # sfn_state_machine_timeouts = {
  #   create = "30m"
  #   delete = "50m"
  #   update = "30m"
  # }

  tags = local.tags
}
