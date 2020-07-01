output "instance_private_ip" {
  description = "EC2 private ip address"
  value       = module.prometheus_grafana.aws_instance_private_ip
}

output "private_domain_name_prometheus" {
  description = "Private domain name: Prometheus"
  value       = module.prometheus_grafana.dns_record_private[0]
}

output "private_domain_name_grafana" {
  description = "Private domain name: Grafana"
  value       = module.prometheus_grafana.dns_record_private[1]
}