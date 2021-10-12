output "endpoint" {
  description = "ElasticSearch Endpoint"
  value       = module.managed_elasticsearch_kibana.endpoint
}

output "kibana_endpoint" {
  description = "Kibana Endpoint"
  value       = module.managed_elasticsearch_kibana.kibana_endpoint
}
