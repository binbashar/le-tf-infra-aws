#
# AWS Config
#
output "bucket_arn" {
  value = "${aws_s3_bucket.config.arn}"
}

output "recorder_id" {
  value = "${aws_config_configuration_recorder.config.id}"
}
