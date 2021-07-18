output "network_firewall_status" {
  description = "Nested list of information about the current status of the firewall."
  #value       = { for v in aws_networkfirewall_firewall.firewall.firewall_status.*.sync_states : v["availability_zone"] => v["attachment"]["endpoint_id"] }
  value = aws_networkfirewall_firewall.firewall.firewall_status
}

output "sync_states" {
  description = "Set of subnets configured for use by the firewall."
  value       = aws_networkfirewall_firewall.firewall.firewall_status.*.sync_states
}
#
#output "network_firewall_status_sync_states_attachment" {
#  description = "Nested list describing the attachment status of the firewall's association with a single VPC subnet."
#  value       = lookup(aws_networkfirewall_firewall.firewall.firewall_status[0]["sync_states"], "attachment")
#}
output "network_firewall_subnet_id_endpoint_id" {
  description = "Map of endpoint_id per subnet_id"
  value       = { for v in aws_networkfirewall_firewall.firewall.firewall_status[0]["sync_states"].*.attachment : v[0]["subnet_id"] => v[0]["endpoint_id"] }
}
