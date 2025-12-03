# Domain list inspection for traffic from outside the Network Firewall VPC
To use domain name filtering for traffic from outside the VPC where you've deployed Network Firewall, you must manually set the `HOME_NET` variable for the rule group. The most common use case for this is a central firewall VPC with traffic coming from other VPCs through a transit gateway.

Include the `HOME_NET` variable in the dtaeful group definiton as follow:

```
  # Stateful rules
  stateful_rule_groups = {
    # rules_source_list examples
    stateful-group-1 = {
      description = "Stateful Inspection for denying access to domains"
      capacity    = 100
      rule_variables = {
        ip_sets = {
          HOME_NET = ["0.0.0.0/0"]
        }
      }
      rules_source_list = {
        generated_rules_type = "DENYLIST"
        target_types         = ["TLS_SNI", "HTTP_HOST"]
        targets              = [".wikipedia.org", ".bad-domain.com"]
      }
    }
  }
}
```
**Reference**: [Domain list inspection for traffic from outside the deployment VPC](https://docs.aws.amazon.com/network-firewall/latest/developerguide/stateful-rule-groups-domain-names.html#:~:text=see%20Domain%20filtering.-,Domain%20list%20inspection%20for%20traffic%20from%20outside%20the%20deployment%20VPC,-To%20use%20domain)

