resource "awscc_bedrock_data_automation_project" "kyb_project" {
  project_name        = local.bda_project_name
  project_description = "Bedrock Data Automation project for Know Your Business (KYB) document processing and compliance data extraction"

  # Custom output configuration with blueprint for KYB extraction
  custom_output_configuration = {
    blueprints = [
      {
        blueprint_arn     = awscc_bedrock_blueprint.kyb_blueprint.blueprint_arn
        blueprint_stage   = "LIVE"
        blueprint_version = "1"
      }
    ]
  }

  # Standard output configuration for basic document processing
  standard_output_configuration = {
    document = {
      extraction = {
        bounding_box = {
          state = "DISABLED"
        }
        granularity = {
          types = ["DOCUMENT", "PAGE", "ELEMENT"]
        }
      }
      generative_field = {
        state = "ENABLED"
      }
      output_format = {
        additional_file_format = {
          state = "ENABLED"
        }
        text_format = {
          types = ["PLAIN_TEXT", "MARKDOWN", "CSV"]
        }
      }
    }
  }

  # Override configuration for specific processing behaviors
  override_configuration = {
    document = {
      splitter = {
        state = "ENABLED"
      }
    }
  }

  # KMS encryption configuration
  kms_key_id = var.enable_encryption ? data.terraform_remote_state.keys.outputs.aws_kms_key_arn : null

  kms_encryption_context = var.enable_encryption ? {
    project = var.project
    environment = var.environment
    purpose = "kyb-data-automation"
  } : null

  tags = [
    for key, value in local.tags : {
      key   = key
      value = value
    }
  ]

  # Ensure proper creation order
  depends_on = [
    awscc_bedrock_blueprint.kyb_blueprint,
    null_resource.blueprint_version
  ]
}

resource "awscc_bedrock_blueprint" "kyb_blueprint" {
  blueprint_name = "${local.bda_project_name}-blueprint"
  
  # Custom schema for KYB data extraction
  schema = var.kyb_extraction_schema
  
  # Type of blueprint - DOCUMENT for business document processing
  type = "DOCUMENT"

  # KMS encryption configuration
  kms_key_id = var.enable_encryption ? data.terraform_remote_state.keys.outputs.aws_kms_key_arn : null

  kms_encryption_context = var.enable_encryption ? {
    project = var.project
    environment = var.environment
    purpose = "kyb-blueprint"
  } : null

  tags = [
    for key, value in merge(local.tags, { Purpose = "kyb-blueprint" }) : {
      key   = key
      value = value
    }
  ]
}

# Create blueprint version using AWS CLI since Terraform doesn't support it directly
resource "null_resource" "blueprint_version" {
  triggers = {
    blueprint_arn = awscc_bedrock_blueprint.kyb_blueprint.blueprint_arn
    schema_hash   = md5(var.kyb_extraction_schema)
  }

  provisioner "local-exec" {
    command = <<-EOT
      # Wait for blueprint to be available and create version
      sleep 10
      aws bedrock-data-automation create-blueprint-version \
        --blueprint-arn ${awscc_bedrock_blueprint.kyb_blueprint.blueprint_arn} \
        --region us-east-1 \
        --profile bb-data-science-devops || true
    EOT
  }

  depends_on = [awscc_bedrock_blueprint.kyb_blueprint]
}