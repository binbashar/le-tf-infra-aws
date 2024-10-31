## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | ~> 2.27 |

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_cluster"></a> [cluster](#module\_cluster) | github.com/binbashar/terraform-aws-eks.git | v19.21.0 |
| <a name="module_iam_policy_ecr_pullthrough_cache"></a> [iam\_policy\_ecr\_pullthrough\_cache](#module\_iam\_policy\_ecr\_pullthrough\_cache) | github.com/binbashar/terraform-aws-iam.git//modules/iam-policy | v4.24.1 |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_additional_node_groups"></a> [additional\_node\_groups](#input\_additional\_node\_groups) | Additional node groups | `map` | `{}` | no |
| <a name="input_ami_type"></a> [ami\_type](#input\_ami\_type) | Default AMI type for nodes | `string` | `"AL2_x86_64"` | no |
| <a name="input_aws_kms_key_arn"></a> [aws\_kms\_key\_arn](#input\_aws\_kms\_key\_arn) | KMS Key to encrypt selected k8s resources (secrets) | `string` | n/a | yes |
| <a name="input_cluster_endpoint_private_access"></a> [cluster\_endpoint\_private\_access](#input\_cluster\_endpoint\_private\_access) | Indicates whether or not the Amazon EKS private API server endpoint is enabled. | `bool` | `true` | no |
| <a name="input_cluster_endpoint_public_access"></a> [cluster\_endpoint\_public\_access](#input\_cluster\_endpoint\_public\_access) | Indicates whether or not the Amazon EKS public API server endpoint is enabled. | `bool` | `false` | no |
| <a name="input_cluster_log_retention_in_days"></a> [cluster\_log\_retention\_in\_days](#input\_cluster\_log\_retention\_in\_days) | Number of days to retain log events. Default retention - 90 days. | `number` | `60` | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Name to use for the EKS cluster. | `string` | n/a | yes |
| <a name="input_cluster_version"></a> [cluster\_version](#input\_cluster\_version) | Kubernetes version to use for the EKS cluster. | `string` | `"1.28"` | no |
| <a name="input_create_aws_auth"></a> [create\_aws\_auth](#input\_create\_aws\_auth) | Whether to create the aws-auth configmap. | `bool` | `false` | no |
| <a name="input_create_cluster_security_group"></a> [create\_cluster\_security\_group](#input\_create\_cluster\_security\_group) | Whether to create security group rules for the access to the Amazon EKS private API server endpoint. | `bool` | `true` | no |
| <a name="input_create_default_node_groups"></a> [create\_default\_node\_groups](#input\_create\_default\_node\_groups) | Whether to create the default node groups (one per subnet) | `bool` | `true` | no |
| <a name="input_disk_size"></a> [disk\_size](#input\_disk\_size) | Default disk size for nodes | `number` | `50` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | The environment name | `string` | n/a | yes |
| <a name="input_instance_types"></a> [instance\_types](#input\_instance\_types) | Default instance types list for nodes | `list(string)` | <pre>[<br>  "t2.medium"<br>]</pre> | no |
| <a name="input_manage_aws_auth"></a> [manage\_aws\_auth](#input\_manage\_aws\_auth) | Whether to apply the aws-auth configmap file. | `bool` | `true` | no |
| <a name="input_map_accounts"></a> [map\_accounts](#input\_map\_accounts) | Map of account to add to the cluster | `list` | `[]` | no |
| <a name="input_map_roles"></a> [map\_roles](#input\_map\_roles) | Map of roles to add to the cluster | <pre>list(object({<br>      rolearn  = string<br>      username = string<br>      groups   = list(string)<br>  }))</pre> | `[]` | no |
| <a name="input_map_users"></a> [map\_users](#input\_map\_users) | Map of users to add to the cluster | `list` | `[]` | no |
| <a name="input_node_group_capacity_type"></a> [node\_group\_capacity\_type](#input\_node\_group\_capacity\_type) | Capacity type for node group (e.g. SPOT) | `string` | `"SPOT"` | no |
| <a name="input_node_group_desired_size"></a> [node\_group\_desired\_size](#input\_node\_group\_desired\_size) | Desired size for node group | `number` | `1` | no |
| <a name="input_node_group_instance_types"></a> [node\_group\_instance\_types](#input\_node\_group\_instance\_types) | Instance types for node group | `list(string)` | <pre>[<br>  "t3.medium"<br>]</pre> | no |
| <a name="input_node_group_max_size"></a> [node\_group\_max\_size](#input\_node\_group\_max\_size) | Max size for node group | `number` | `6` | no |
| <a name="input_node_group_min_size"></a> [node\_group\_min\_size](#input\_node\_group\_min\_size) | Min size for node group | `number` | `1` | no |
| <a name="input_profile"></a> [profile](#input\_profile) | The AWS profile | `string` | n/a | yes |
| <a name="input_project"></a> [project](#input\_project) | The project name | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | The AWS region | `string` | n/a | yes |
| <a name="input_shared_vpc_cidr_block"></a> [shared\_vpc\_cidr\_block](#input\_shared\_vpc\_cidr\_block) | VPC CIDR to use for the EKS nodes inbound rule. | `string` | n/a | yes |
| <a name="input_subnet_cidrs"></a> [subnet\_cidrs](#input\_subnet\_cidrs) | Subnet CIDRs to use for the EKS nodes outbound rule. | `list(string)` | n/a | yes |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | List of subnet ids to use for the EKS cluster. | `list(string)` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Extra tags | `map(string)` | `{}` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | VPC id to use for the EKS cluster. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cluster_endpoint"></a> [cluster\_endpoint](#output\_cluster\_endpoint) | Endpoint for EKS control plane. |
| <a name="output_cluster_iam_role_name"></a> [cluster\_iam\_role\_name](#output\_cluster\_iam\_role\_name) | n/a |
| <a name="output_cluster_id"></a> [cluster\_id](#output\_cluster\_id) | EKS Cluster ID |
| <a name="output_cluster_kubeconfig_instructions"></a> [cluster\_kubeconfig\_instructions](#output\_cluster\_kubeconfig\_instructions) | Instructions to generate a kubeconfig file. |
| <a name="output_cluster_name"></a> [cluster\_name](#output\_cluster\_name) | EKS Cluster Name |
| <a name="output_cluster_oidc_issuer_url"></a> [cluster\_oidc\_issuer\_url](#output\_cluster\_oidc\_issuer\_url) | EKS OpenID Connect Issuer URL. |
| <a name="output_cluster_oidc_provider_arn"></a> [cluster\_oidc\_provider\_arn](#output\_cluster\_oidc\_provider\_arn) | EKS OpenID Connect Provider ARN. |
| <a name="output_cluster_primary_security_group_id"></a> [cluster\_primary\_security\_group\_id](#output\_cluster\_primary\_security\_group\_id) | Security group ids attached to the cluster control plane. |
| <a name="output_cluster_version"></a> [cluster\_version](#output\_cluster\_version) | EKS Cluster Version |
