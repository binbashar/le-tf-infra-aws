locals {

  name = "${var.project}-${var.environment}-genai-llm-rag-bedrock"
  tags = {
    Terraform   = "true"
    Environment = var.environment
  }

  container_definitions = {
    demo = {
      image                     = "905418344519.dkr.ecr.us-east-1.amazonaws.com/bb-data-science-genai-llm-rag-bedrock-demo:latest"
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
          "name" : "BEDROCK_REGION"
          "value" : "us-west-2"
        },
        {
          "name" : "USER"
          "value" : "demo"
        },
        {
          "name" : "CROSS_ACCOUNT_ROLE_ARN"
          "value" : module.iam_assumable_role_ecs_opensearch.iam_role_arn
        },
        {
          "name" : "OPENSEARCH_INDEX_NAME"
          "value" : "main"
        },
        {
          "name" : "OPENSEARCH_DOMAIN"
          "value" : aws_opensearchserverless_collection.this.id
        },
      ]
      secrets = [
        {
          "name" : "PWD"
          "valueFrom" : "${module.secrets.secret_arns["demo"]}:PWD_DEMO::"
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

  clusters = {
    bedrock-knowledge-base = {
      description = "Amazon Bedrock Knowledge base."
      access_policy = {
        Rules = [
          {
            Resource = ["collection/bedrock-knowledge-base"]
            Permission = [
              "aoss:DescribeCollectionItems",
              "aoss:CreateCollectionItems",
              "aoss:UpdateCollectionItems"
            ]
            ResourceType = "collection"
          },
          {
            Resource = ["index/bedrock-knowledge-base/*"]
            Permission = [
              "aoss:UpdateIndex",
              "aoss:DescribeIndex",
              "aoss:ReadDocument",
              "aoss:WriteDocument",
              "aoss:CreateIndex"
            ]
            ResourceType = "index"
          }
        ]
        Principal = [
          data.aws_caller_identity.current.arn,

        ]
        Description = ""
      }
    }
  }
}



