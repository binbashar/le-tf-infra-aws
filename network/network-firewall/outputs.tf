#output "network_firewall_status" {
##  description = "Nested list of information about the current status of the firewall."
#  value       = aws_networkfirewall_firewall.firewall.firewall_status
#}
#
#output "network_firewall_status_sync_states" {
#  description = "Set of subnets configured for use by the firewall."
#  value       = aws_networkfirewall_firewall.firewall.firewall_status[0]["sync_states"]
#}
#
#output "network_firewall_status_sync_states_attachment" {
#  description = "Nested list describing the attachment status of the firewall's association with a single VPC subnet."
#  value       = lookup(aws_networkfirewall_firewall.firewall.firewall_status[0]["sync_states"], "attachment")
#}
