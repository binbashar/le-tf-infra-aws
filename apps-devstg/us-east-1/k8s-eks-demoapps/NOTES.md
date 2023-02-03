# Notes

## Cluster creation

### Error: The configmap "aws-auth" does not exist

As per this [issue](https://github.com/terraform-aws-modules/terraform-aws-eks/issues/2009).

Added this to `variables.tf`:

```yaml
variable "create_aws_auth" {
  description = "Whether to create the aws-auth configmap."
  default     = false
}
```

and this to `eks-workers-managed.tf`:

```yaml
  create_aws_auth_configmap = var.create_aws_auth
```
