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
    ] , 
    "AWSOwnedKey" = true  
})
}

resource "aws_opensearchserverless_security_policy" "network" {
  name     = "bedrock-knowledge-base"
  type     = "network"
  #description = each.value.description
  policy = jsonencode([
    {
      Rules = [
          {
            Resource = ["collection/bedrock-knowledge-base"]
            ResourceType = "collection"
          },
          {
            Resource = ["collection/bedrock-knowledge-base"]
            ResourceType = "dashboard"
        # Principal = [
        #   module.iam_assumable_role_ecs_opensearch.iam_role_arn
        # ]

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
  policy      = jsonencode([{
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


# resource "aws_opensearchserverless_security_config" "this" {
#   count       = var.create_security_config ? 1 : 0
#   name        = coalesce(var.security_config_name, "${var.name}-security-config")
#   description = var.security_config_description
#   type        = "saml"
#   saml_options {
#     metadata        = file(var.saml_metadata)
#     group_attribute = var.saml_group_attribute
#     user_attribute  = var.saml_user_attribute
#     session_timeout = var.saml_session_timeout
#   }
# }

##################
# Security Group
##################
resource "aws_security_group" "this" {
  name        = "opensearch-security-group"
  #description = var.vpce_security_group_description
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id
  ingress {
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    #ipv6_cidr_blocks = flatten([for i, item in var.vpce_security_group_sources : [for k, source in item.sources : source] if item.type == "IPv6"])
    #prefix_list_ids  = flatten([for i, item in var.vpce_security_group_sources : [for k, source in item.sources : source] if item.type == "PrefixLists"])
    #security_groups  = flatten([for i, item in var.vpce_security_group_sources : [for k, source in item.sources : source] if item.type == "SGs"])
    description      = "Allow Inbound HTTPS Traffic"
#   }
#   tags = merge(
#     var.tags,
#     {
#       Name : local.sg_name
#     }
#   )
}
}