module "managed_elasticsearch_kibana" {
  source = "github.com/binbashar/terraform-aws-elasticsearch?ref=0.9.1"

  # Domain (cluster) name and ElasticSearch version
  domain_name           = local.domain_name
  elasticsearch_version = "7.10"

  # Cluster settings
  cluster_config = {
    dedicated_master_enabled = false
    instance_count           = "1"
    instance_type            = "t3.medium.elasticsearch"
    zone_awareness_enabled   = false
    availability_zone_count  = "1"
  }

  # VPC settings
  vpc_options = {
    subnet_ids         = tolist([data.terraform_remote_state.vpc.outputs.private_subnets[0]])
    security_group_ids = tolist([aws_security_group.eskibana.id])
  }

  # EBS volume settings
  ebs_options = {
    ebs_enabled = true
    volume_size = "10"
  }

  # Configure encryption at-rest
  encrypt_at_rest = {
    enabled    = true
    kms_key_id = data.aws_kms_key.elasticsearch.arn
  }

  # Enable logging to CloudWatch
  log_publishing_options = {
    enabled  = false
    log_type = "INDEX_SLOW_LOGS"
  }

  # Use a custom domain
  domain_endpoint_options = {
    custom_endpoint_enabled         = false
    custom_endpoint                 = "es.aws.binbash.com.ar"
    custom_endpoint_certificate_arn = "arn:aws:acm:us-east-1:111111111111:certificate/abcd1234"
    enforce_https                   = true
  }

  # Set up node-to-node encryption
  node_to_node_encryption_enabled = false

  # Configure automated snapshot start time
  snapshot_options_automated_snapshot_start_hour = "23"

  # Open access policy
  access_policies = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "es:*",
      "Principal": {
        "AWS": ["*"]
      },
      "Resource": "arn:aws:es:${var.region}:${var.shared_account_id}:domain/${local.domain_name}/*"
    }
  ]
}
POLICY

  # Configure advanced options
  advanced_options = {
    "rest.action.multi.allow_explicit_index" = true
  }

  tags = local.tags
}
