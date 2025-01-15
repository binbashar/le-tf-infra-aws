data "aws_ssoadmin_instances" "this" {
  provider = aws.management
}

data "aws_identitystore_group" "devops" {
  provider = aws.management

  identity_store_id = tolist(data.aws_ssoadmin_instances.this.identity_store_ids)[0]

  alternate_identifier {
    unique_attribute {
      attribute_path  = "DisplayName"
      attribute_value = "DevOps"
    }
  }
}

output "group_id" {
  value = data.aws_identitystore_group.devops.group_id
}