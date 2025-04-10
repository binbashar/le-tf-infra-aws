resource "aws_opensearchserverless_collection" "this" {
  name             = "bedrock-knowledge-base"
  description      = "Amazon Bedrock Knowledge base."
  standby_replicas = "ENABLED"
  type             = "VECTORSEARCH"
  tags             = local.tags
  depends_on       = [aws_opensearchserverless_security_policy.encryption]
}

resource "aws_opensearchserverless_security_policy" "encryption" {
  name        = "bedrock-knowledge-base"
  type        = "encryption"
  description = "Amazon Bedrock Knowledge base."
  policy = jsonencode({
    "Rules" = [
      {
        "Resource"     = ["collection/bedrock-knowledge-base"]
        "ResourceType" = "collection"
      }
    ],
    "AWSOwnedKey" = true
  })
}

resource "aws_opensearchserverless_security_policy" "network" {
  name = "bedrock-knowledge-base"
  type = "network"
  policy = jsonencode([
    {
      Rules = [
        {
          Resource     = ["collection/bedrock-knowledge-base"]
          ResourceType = "collection"
        },
        {
          Resource     = ["collection/bedrock-knowledge-base"]
          ResourceType = "dashboard"
        }
      ]
      AllowFromPublic = true

    }
  ])
}


resource "aws_opensearchserverless_access_policy" "this" {
  name        = "bedrock-knowledge-base"
  type        = "data"
  description = "Amazon Bedrock Knowledge base."
  policy = jsonencode([{
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
      module.iam_assumable_role_ecs_opensearch.iam_role_arn
    ]
    Description = "Amazon Bedrock Knowledge base."
  }])
}

##################
# Security Group
##################
resource "aws_security_group" "this" {
  name   = "opensearch-security-group"
  vpc_id = data.terraform_remote_state.vpc.outputs.vpc_id
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow Inbound HTTPS Traffic"
  }
}