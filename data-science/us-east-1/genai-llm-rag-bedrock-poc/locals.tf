locals {

  name = "${var.project}-${var.environment}-genai-llm-rag-bedrock-poc"
  tags = {
    Terraform   = "true"
    Environment = var.environment
  }

  container_definitions = {
    b2chat = {
      image                     = "905418344519.dkr.ecr.us-east-1.amazonaws.com/bb-data-science-genai-llm-rag-bedrock-poc-b2chat:latest"
      enable_cloudwatch_logging = false
      readonly_root_filesystem  = false
      cpu                       = 512
      memory                    = 1024
      port_mappings = [
        {
          "containerPort" : 8080,
          "hostPort" : 8080,
          "protocol" : "tcp"
        }
      ]
      environment = [
        {
          "name" : "AWS_DEFAULT_REGION"
          "value" : "us-east-1"
        },
        {
          "name" : "USER"
          "value" : "b2chat"
        }
      ]
      secrets = [
        {
          "name" : "PWD"
          "valueFrom" : "${module.secrets.secret_arns["/data-science/genai-llm-rag-poc"]}:PWD_B2CHAT::"
        }
      ]
    }
  }

  allowed_cidr = [
    {
      cidr        = "0.0.0.0/0",
      description = "Allow public access"
    }
  ]

  iam_role_statements = {
    bedrock = {
      actions = [
        "bedrock:InvokeModelWithResponseStream",
      "bedrock:InvokeModel"]
      effect    = "Allow"
      resources = ["*"]
    }
  }
}



