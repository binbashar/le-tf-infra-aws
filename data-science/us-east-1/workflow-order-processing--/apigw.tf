#======================================
# API Gateway: Callback Handler
#======================================

module "apigw_order" {
  source = "github.com/SPHTech-Platform/terraform-aws-apigw.git?ref=v0.4.11"

  name  = "OrderApi"
  stage = "v1"

  body_template = <<EOF
    swagger: "2.0"
    info:
      version: "2018-10-02T12:08:57Z"
      title: "CallbackPattern"
    basePath: "/v1"
    schemes:
    - "https"
    paths:
      /externalCallback:
        post:
          operationId: "setExternalTaskStatus"
          consumes:
            - "application/json"
          produces:
            - "application/json"
          parameters:
            - in: "body"
              name: "ExternalCallbackRequest"
              required: true
              schema:
                $ref: "#/definitions/ExternalCallbackTaskStatusRequest"
          responses:
            "200":
              description: "Task status sent successfully"
            "400":
              description: "Invalid request"
            "500":
              description: "Internal server error"
          security:
            - sigv4: []
          x-amazon-apigateway-request-validator: "Validate body"
          x-amazon-apigateway-integration:
            credentials: "${module.role_apigw.iam_role_arn}"
            uri: "${module.functions["ExternalCallbackFunction"].lambda_function_invoke_arn}"
            requestTemplates:
              application/json: "$input.body"
            responses:
              default:
                statusCode: "200"
              .*Bad Request.*:
                statusCode: "400"
                responseTemplates:
                  application/json: "#set($inputRoot = $input.path('$')) { 'message' : $input.json('$.errorMessage') }"
            passthroughBehavior: "when_no_templates"
            httpMethod: "POST"
            contentHandling: "CONVERT_TO_TEXT"
            type: "aws"
    securityDefinitions:
      sigv4:
        type: "apiKey"
        name: "Authorization"
        in: "header"
        x-amazon-apigateway-authtype: "awsSigv4"
    definitions:
      ExternalCallbackTaskStatusRequest:
        type: "object"
        required:
        - "order_id"
        - "task_type"
        - "task_status"
        properties:
          order_id:
            type: "string"
          task_type:
            $ref: "#/definitions/ExternalCallbackTaskType"
          task_status:
            $ref: "#/definitions/ExternalCallbackTaskStatus"
          task_output:
            type: "object"
            additionalProperties: true
          task_error:
            type: "object"
            additionalProperties: true
          task_cause:
            type: "object"
            additionalProperties: true
      ExternalCallbackTaskStatus:
        type: "string"
        enum:
          - "SUCCEEDED"
          - "FAILED"
      ExternalCallbackTaskType:
        type: "string"
        enum:
          - "ORDER_SHIPPING_SERVICE"
      Empty:
        type: "object"
        title: "Empty Schema"
    x-amazon-apigateway-request-validators:
      Validate body:
        validateRequestParameters: false
        validateRequestBody: true
      Validate parameters:
        validateRequestParameters: true
        validateRequestbody: false
  EOF

  metrics_enabled             = true
  data_trace_enabled          = true
  enable_global_apigw_logging = true
  tags                        = local.tags
}
