# AWS Client VPN

This layer deploy the AWS Client VPN service using AWS SSO to authenticate users.

## Configure AWS SSO

Due to API limitations, the SSO application must be configured manually (For more information regarding this limitation you can check [this bug](https://github.com/hashicorp/terraform-provider-aws/issues/34813) and the [notes in the AWS Terraform Provider](https://registry.terraform.io/providers/hashicorp/aws/5.39.1/docs/resources/ssoadmin_application?lang=typescript)).

1. In the AWs Identity Center go to to “Applications”, then click the “Add a new application” button, then click “Add a custom SAML 2.0 application”.
2. Complete the Name and description (if you will import this resource to terrraform note than you will not be able to change the name).
3. Download the AWS SSO Metadata file (with name `saml-metadata.xml` in this folder, it will be ignored by git for security reasons)
4. Enter `http://127.0.0.1:35001` as the Application ACS URL and `urn:amazon:webservices:clientvpn` as the Application SAML audience.
5. Set up the following attributes mappings: the `Subject` needs to have the value of `${user:email}` and the format `emailAddress`. The `memberOf` attribute has a value of `${user:groups`} and should have the format `unspecified`.

You can read a more complete guide in [this AWs Post](https://aws.amazon.com/es/blogs/networking-and-content-delivery/using-aws-sso-with-aws-client-vpn-for-authentication-and-authorization/). Note that some of the steps are done automatically using Terraform.

### SSO Layer in Leverage

To configure the group assignment as code, you can import the SSO Application in `management/global/sso`. 

```bash
leverage tf import 'aws_ssoadmin_application.client_vpn[0]' application-arn
```

And configure this section in locals.tf:

```hcl
locals{
  enable_sso_client_vpn = true

  client_vpn_groups = [
    "devops"
  ]
}
```

 Alternativelly, you can use a local or variable to pass the application arn to the group assignemt resource

 ```hcl
resource "aws_ssoadmin_application_assignment" "client_vpn" {
  for_each = local.enable_sso_client_vpn == true ? toset(local.client_vpn_groups) : toset([])

  application_arn = local.aws_vpn_sso_application_arn # <<- Here
  principal_id    = split("/", aws_identitystore_group.default[each.key].id)[1]
  principal_type  = "GROUP"
}
 ```

 ## Configure VPN

 ### Routes

It is posible to add a route to 0.0.0.0/0 in the VPN. However, this will break the split tunnel funtionality, and may cause problems with the authorizations.

 ### Users

 The users or groups should be firist allowed in the SSO Application, and also authorized in the VPN. If the user applying this layer do not have permissions to assume a role in the management account, you can remove `sso-groups.tf` and pass the group Ids as a local or variable.

 You can authorize different target CIDRs for different groups. However it will always use the same Security Group.


<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.3 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.83.1 |
| <a name="provider_aws.management"></a> [aws.management](#provider\_aws.management) | 5.83.1 |
| <a name="provider_terraform"></a> [terraform](#provider\_terraform) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_vpn_sso_sg"></a> [vpn\_sso\_sg](#module\_vpn\_sso\_sg) | github.com/binbashar/terraform-aws-security-group | v5.1.2 |

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_log_group.sso](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_ec2_client_vpn_authorization_rule.sso_devops](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_client_vpn_authorization_rule) | resource |
| [aws_ec2_client_vpn_endpoint.sso](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_client_vpn_endpoint) | resource |
| [aws_ec2_client_vpn_network_association.this_sso](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_client_vpn_network_association) | resource |
| [aws_ec2_client_vpn_route.vpn_routes](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_client_vpn_route) | resource |
| [aws_iam_saml_provider.client_vpn](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_saml_provider) | resource |
| [aws_identitystore_group.devops](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/identitystore_group) | data source |
| [aws_ssoadmin_instances.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ssoadmin_instances) | data source |
| [terraform_remote_state.apps_devstg_vpcs](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/data-sources/remote_state) | data source |
| [terraform_remote_state.apps_prd_vpcs](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/data-sources/remote_state) | data source |
| [terraform_remote_state.certs](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/data-sources/remote_state) | data source |
| [terraform_remote_state.keys](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/data-sources/remote_state) | data source |
| [terraform_remote_state.network_vpcs](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/data-sources/remote_state) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_accounts"></a> [accounts](#input\_accounts) | Accounts Information | `map(any)` | n/a | yes |
| <a name="input_bucket"></a> [bucket](#input\_bucket) | AWS S3 TF State Backend Bucket | `string` | n/a | yes |
| <a name="input_dynamodb_table"></a> [dynamodb\_table](#input\_dynamodb\_table) | AWS DynamoDB TF Lock state table name | `string` | n/a | yes |
| <a name="input_enable_inspector"></a> [enable\_inspector](#input\_enable\_inspector) | Turn inspector on/off | `bool` | `false` | no |
| <a name="input_enable_tgw"></a> [enable\_tgw](#input\_enable\_tgw) | Enable Transit Gateway Support | `bool` | `false` | no |
| <a name="input_enable_tgw_multi_region"></a> [enable\_tgw\_multi\_region](#input\_enable\_tgw\_multi\_region) | Enable Transit Gateway multi region support | `bool` | `false` | no |
| <a name="input_encrypt"></a> [encrypt](#input\_encrypt) | Enable AWS DynamoDB with server side encryption | `bool` | n/a | yes |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment Name | `string` | n/a | yes |
| <a name="input_external_accounts"></a> [external\_accounts](#input\_external\_accounts) | External Accounts Information | `map(any)` | `{}` | no |
| <a name="input_profile"></a> [profile](#input\_profile) | AWS Profile (required by the backend but also used for other resources) | `string` | n/a | yes |
| <a name="input_project"></a> [project](#input\_project) | Project Name | `string` | n/a | yes |
| <a name="input_project_long"></a> [project\_long](#input\_project\_long) | Project Long Name | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | AWS Region | `string` | n/a | yes |
| <a name="input_region_primary"></a> [region\_primary](#input\_region\_primary) | AWS Region | `string` | n/a | yes |
| <a name="input_region_secondary"></a> [region\_secondary](#input\_region\_secondary) | AWS Secondary Region for HA | `string` | n/a | yes |
| <a name="input_sso_enabled"></a> [sso\_enabled](#input\_sso\_enabled) | Enable SSO Service | `string` | n/a | yes |
| <a name="input_sso_region"></a> [sso\_region](#input\_sso\_region) | SSO Region | `string` | n/a | yes |
| <a name="input_sso_role"></a> [sso\_role](#input\_sso\_role) | SSO Role Name | `any` | n/a | yes |
| <a name="input_sso_start_url"></a> [sso\_start\_url](#input\_sso\_start\_url) | SSO Start Url | `string` | n/a | yes |
| <a name="input_tgw_cidrs"></a> [tgw\_cidrs](#input\_tgw\_cidrs) | CIDRs to be added as routes to public RT | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_sso_vpn_sg"></a> [sso\_vpn\_sg](#output\_sso\_vpn\_sg) | n/a |
<!-- END_TF_DOCS -->