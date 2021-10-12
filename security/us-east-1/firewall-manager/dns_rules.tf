resource "aws_route53_resolver_firewall_domain_list" "example" {
  name    = "example"
  domains = ["example.com"]
  tags    = {}
}

resource "aws_route53_resolver_firewall_rule_group" "example" {
  name = "example"
  tags = {}
}

resource "aws_route53_resolver_firewall_rule" "example" {
  name                    = "example"
  action                  = "BLOCK"
  block_override_dns_type = "CNAME"
  block_override_domain   = "example.com"
  block_override_ttl      = 1
  block_response          = "OVERRIDE"
  firewall_domain_list_id = aws_route53_resolver_firewall_domain_list.example.id
  firewall_rule_group_id  = aws_route53_resolver_firewall_rule_group.example.id
  priority                = 100
}
