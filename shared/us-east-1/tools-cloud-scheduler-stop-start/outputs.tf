output "start_http_endpoint" {
  description = "The http endpoint to trigger start"
  value       = module.schedule_ec2_start_daily_morning.http_trigger
}

output "stop_http_endpoint" {
  description = "The http endpoint to trigger stop"
  value       = module.schedule_ec2_stop_daily_midnight.http_trigger
}
