# binbash Leverage Network module

## Overview

This module can be used to create a VPC and its associated resources in the context of **binbash Leverage Landing Zone**

### About binbash Leverage Landing Zone 

See [here](https://leverage.binbash.co/try-leverage/) for more info on the **binbash Leverage Landing Zone**.

Basically, there is a `shared` AWS Account in which networking is centralized. Also in this accounts there are resources such VPN server and internal Route 53 Private DNS.

Because of this, all the new VPCs are created with a VPC Peering to `shared` base network and are associated with the private DNS. (both can be turned off)

### Resources

#### VPC

This module will create a VPC with a specific CIDR.

#### Public Private CIDR Zones

If enabled, will create two CIDRs, one for private networks and one for public ones.

#### Subnets and AZs

Up to 4 AZs can be set, e.g. a, b and c. The name will be the concatenation of the region with the letters. For this example and us-east-1: us-east-1a, us-east-1b, us-east-1c.

If enables public subnets, one public subnet will be created per AZ.

If enables private subnets, one private subnet will be created per AZ.

#### Nat gateway

If enabled one will be created

#### Private DNS Association in `shared` account

Association with private DNS zone will be created.

As per **binbash Leverage Landing Zone** the DNS will exist in `shared` account.

The private zone id has to be provided.

#### `shared` account VPC Peerings

If enabled, VPC peerings to base `shared` account VPC will be created.

This can be ovewriten to add/change VPCs.

#### VPC Flow logs

If enabled, VPC Flow logs will be set.

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.20 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 5.20 |
| <a name="provider_aws.shared"></a> [aws.shared](#provider\_aws.shared) | ~> 5.20 |
| <a name="provider_terraform"></a> [terraform](#provider\_terraform) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_vpc"></a> [vpc](#module\_vpc) | github.com/binbashar/terraform-aws-vpc.git | v5.5.3 |
| <a name="module_vpc_endpoints"></a> [vpc\_endpoints](#module\_vpc\_endpoints) | github.com/binbashar/terraform-aws-vpc.git//modules/vpc-endpoints | v5.5.3 |
| <a name="module_vpc_flow_logs"></a> [vpc\_flow\_logs](#module\_vpc\_flow\_logs) | github.com/binbashar/terraform-aws-vpc-flowlogs.git | v1.0.18 |
| <a name="module_vpc_peering"></a> [vpc\_peering](#module\_vpc\_peering) | github.com/binbashar/terraform-aws-vpc-peering.git | v6.0.0 |

## Resources

| Name | Type |
|------|------|
| [aws_route53_vpc_association_authorization.with_shared_vpc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_vpc_association_authorization) | resource |
| [aws_route53_zone_association.with_shared_vpc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_zone_association) | resource |
| [terraform_remote_state.shared-vpcs](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/data-sources/remote_state) | data source |
| [terraform_remote_state.tools-vpn-server](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/data-sources/remote_state) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_additional_acl_rules"></a> [additional\_acl\_rules](#input\_additional\_acl\_rules) | Additional default ACL rules | <pre>list(object({<br>      rule_number = number<br>      rule_action = string<br>      from_port   = number<br>      to_port     = number<br>      protocol    = string<br>      cidr_block  = string<br>  }))</pre> | `null` | no |
| <a name="input_additional_private_acl_rules"></a> [additional\_private\_acl\_rules](#input\_additional\_private\_acl\_rules) | Additional private ACL rules | <pre>list(object({<br>      rule_number = number<br>      rule_action = string<br>      from_port   = number<br>      to_port     = number<br>      protocol    = string<br>      cidr_block  = string<br>  }))</pre> | `null` | no |
| <a name="input_availability_zones"></a> [availability\_zones](#input\_availability\_zones) | The letter for the AZ, e.g. ["a", "b"] (max 4 zones) | `list` | <pre>[<br>  "a",<br>  "b"<br>]</pre> | no |
| <a name="input_create_acl_for_shared_vpcs"></a> [create\_acl\_for\_shared\_vpcs](#input\_create\_acl\_for\_shared\_vpcs) | Create the inbound rules to allow traffic from shared vpcs (default or ovewriten by `shared_vpcs`) | `bool` | `true` | no |
| <a name="input_create_acl_for_vpn_ip"></a> [create\_acl\_for\_vpn\_ip](#input\_create\_acl\_for\_vpn\_ip) | Create the inbound rules to allow traffic from VPN Server Private IP (default or ovewriten by `vpn_private_ip`) | `bool` | `true` | no |
| <a name="input_create_private_subnet"></a> [create\_private\_subnet](#input\_create\_private\_subnet) | True to create private subnets | `bool` | `true` | no |
| <a name="input_create_public_subnet"></a> [create\_public\_subnet](#input\_create\_public\_subnet) | True to create public subnets | `bool` | `true` | no |
| <a name="input_create_vpc_peerings_for_shared_vpcs"></a> [create\_vpc\_peerings\_for\_shared\_vpcs](#input\_create\_vpc\_peerings\_for\_shared\_vpcs) | Create the vpc peerings to shared vpcs (default or ovewriten by `shared_vpcs`). `create_acl_for_shared_vpcs` has to be `true`. | `bool` | `true` | no |
| <a name="input_enable_flow_logs"></a> [enable\_flow\_logs](#input\_enable\_flow\_logs) | Enable Flow Logs | `bool` | `false` | no |
| <a name="input_enable_s3_dynamodb_vpce"></a> [enable\_s3\_dynamodb\_vpce](#input\_enable\_s3\_dynamodb\_vpce) | Enable VPC for S3 and Dynamodb in the VPC | `bool` | `true` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | The environment name | `string` | n/a | yes |
| <a name="input_private_subnet_tags"></a> [private\_subnet\_tags](#input\_private\_subnet\_tags) | Tags for the private subnets | `map(string)` | `null` | no |
| <a name="input_project"></a> [project](#input\_project) | The project name | `string` | n/a | yes |
| <a name="input_public_subnet_tags"></a> [public\_subnet\_tags](#input\_public\_subnet\_tags) | Tags for the public subnets | `map(string)` | `null` | no |
| <a name="input_region"></a> [region](#input\_region) | The AWS region | `string` | n/a | yes |
| <a name="input_route53_private_zone_to_associate"></a> [route53\_private\_zone\_to\_associate](#input\_route53\_private\_zone\_to\_associate) | Private Route53 DNS zone to associate to the new VPC | `string` | `null` | no |
| <a name="input_shared_vpcs"></a> [shared\_vpcs](#input\_shared\_vpcs) | VPC to receive data from. E.g. { "vpcname" => [ "172.18.0.0/21"]}. Used to fill the private ACL inbound rules. `create_acl_for_shared_vpcs` has to be `true`. | `map(list(string))` | `null` | no |
| <a name="input_subnet_bits"></a> [subnet\_bits](#input\_subnet\_bits) | The subnet bits to define the subnets | `number` | `2` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags | `map(string)` | `null` | no |
| <a name="input_vpc_cidr"></a> [vpc\_cidr](#input\_vpc\_cidr) | The VPC CIDR | `string` | n/a | yes |
| <a name="input_vpc_enable_dns_hostnames"></a> [vpc\_enable\_dns\_hostnames](#input\_vpc\_enable\_dns\_hostnames) | Enable DNS HOSTNAME | `bool` | `true` | no |
| <a name="input_vpc_enable_nat_gateway"></a> [vpc\_enable\_nat\_gateway](#input\_vpc\_enable\_nat\_gateway) | Enable NAT Gatewway | `bool` | `false` | no |
| <a name="input_vpc_enable_vpn_gateway"></a> [vpc\_enable\_vpn\_gateway](#input\_vpc\_enable\_vpn\_gateway) | Enable VPN Gateway | `bool` | `false` | no |
| <a name="input_vpc_name_suffix"></a> [vpc\_name\_suffix](#input\_vpc\_name\_suffix) | The suffix to form the vpc name like {var.project}-{var.environment}-vpc-{var.vpc\_name\_suffix} | `string` | n/a | yes |
| <a name="input_vpc_single_nat_gateway"></a> [vpc\_single\_nat\_gateway](#input\_vpc\_single\_nat\_gateway) | Single NAT Gatewway | `bool` | `true` | no |
| <a name="input_vpn_private_ip"></a> [vpn\_private\_ip](#input\_vpn\_private\_ip) | The VPN server private IP | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_availability_zones"></a> [availability\_zones](#output\_availability\_zones) | List of availability zones |
| <a name="output_cluster_name"></a> [cluster\_name](#output\_cluster\_name) | EKS Cluster Name |
| <a name="output_nat_gateway_ids"></a> [nat\_gateway\_ids](#output\_nat\_gateway\_ids) | NAT Gateway IDs |
| <a name="output_private_route_table_ids"></a> [private\_route\_table\_ids](#output\_private\_route\_table\_ids) | List of IDs of private route tables |
| <a name="output_private_subnets"></a> [private\_subnets](#output\_private\_subnets) | List of IDs of private subnets |
| <a name="output_private_subnets_cidr"></a> [private\_subnets\_cidr](#output\_private\_subnets\_cidr) | List of IDs of private subnets |
| <a name="output_public_route_table_ids"></a> [public\_route\_table\_ids](#output\_public\_route\_table\_ids) | List of IDs of public route tables |
| <a name="output_public_subnets"></a> [public\_subnets](#output\_public\_subnets) | List of IDs of public subnets |
| <a name="output_public_subnets_cidr"></a> [public\_subnets\_cidr](#output\_public\_subnets\_cidr) | List of IDs of public subnets |
| <a name="output_vpc_cidr_block"></a> [vpc\_cidr\_block](#output\_vpc\_cidr\_block) | VPC CIDR Block |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | VPC ID |
| <a name="output_vpc_name"></a> [vpc\_name](#output\_vpc\_name) | VPC Name |


