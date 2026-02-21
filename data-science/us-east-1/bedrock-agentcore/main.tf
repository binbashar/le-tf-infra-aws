#=============================#
# Data sources                #
#=============================#
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

#=============================#
# AgentCore Runtime           #
#=============================#
resource "awscc_bedrockagentcore_runtime" "this" {
  agent_runtime_name = "${local.sanitized_name}_runtime"
  description        = var.runtime_description
  role_arn           = aws_iam_role.runtime.arn

  agent_runtime_artifact = {
    code_configuration = {
      code = {
        s3 = {
          bucket     = aws_s3_bucket.code.id
          prefix     = aws_s3_object.agent.key
          version_id = aws_s3_object.agent.version_id
        }
      }
      runtime     = var.runtime_name
      entry_point = var.entry_point
    }
  }

  network_configuration = {
    network_mode = "PUBLIC"
  }

  environment_variables = var.environment_variables
  tags                  = local.tags

  depends_on = [time_sleep.wait_for_iam]
}

#=============================#
# AgentCore Runtime Endpoint  #
#=============================#
resource "awscc_bedrockagentcore_runtime_endpoint" "this" {
  name             = "${local.sanitized_name}_endpoint"
  description      = var.endpoint_description
  agent_runtime_id = awscc_bedrockagentcore_runtime.this.agent_runtime_id
  tags             = local.tags
}
