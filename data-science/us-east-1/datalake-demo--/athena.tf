resource "aws_athena_workgroup" "datalake-workgroup" {
  name = "datalake"

  configuration {
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = false

    result_configuration {
      output_location = "s3://${module.s3_bucket_data_processed.s3_bucket_id}/output/"

      encryption_configuration {
        encryption_option = "SSE_KMS"
        kms_key_arn       = data.terraform_remote_state.keys.outputs.aws_kms_key_arn
      }
    }
  }

  force_destroy = true
}
