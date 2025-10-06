resource "awscc_bedrock_data_automation_project" "kyb_agent" {
  project_name        = local.bda_project_name
  project_description = "BDA project for KYB agent document processing"

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

  tags = [
    for key, value in local.tags : {
      key   = key
      value = value
    }
  ]
}
