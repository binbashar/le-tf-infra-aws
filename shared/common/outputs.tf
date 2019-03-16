# VPC ID
output "vpc_id" {
    value = "${module.vpc.vpc_id}"
}

# Subnets
output "private_subnets" {
  description = "List of IDs of private subnets"
  value       = ["${module.vpc.private_subnets}"]
}
output "public_subnets" {
  description = "List of IDs of public subnets"
  value       = ["${module.vpc.public_subnets}"]
}
output "aws_internal_zone_id" {
  description = "ID internal aws"
  value       = ["${aws_route53_zone.aws.id}"]
}

# AWS Config
output "bucket_arn" {
  value = "${aws_s3_bucket.config.arn}"
}

output "recorder_id" {
  value = "${aws_config_configuration_recorder.config.id}"
}

output "report_bucket_arn" {
  value = "${aws_s3_bucket.reports.arn}"
}