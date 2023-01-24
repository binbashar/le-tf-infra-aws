#
# Ref: https://github.com/philips-labs/terraform-aws-github-runner#overview
#
module "github_selfhosted_runners" {
  source = "github.com/binbashar/terraform-aws-github-runner?ref=v1.18.2"

  # VPC settings
  aws_region = var.region
  vpc_id     = data.terraform_remote_state.vpc.outputs.vpc_id
  subnet_ids = data.terraform_remote_state.vpc.outputs.private_subnets

  # For naming, prefix and tagging purposes
  prefix = "github-runners"

  # Github App credentials
  github_app = {
    key_base64     = local.secrets.github_app_key_base64
    id             = local.secrets.github_app_id
    client_id      = local.secrets.github_app_client_id
    client_secret  = local.secrets.github_app_client_secret
    webhook_secret = local.secrets.github_app_webhook_secret
  }

  # Lambda's code packages
  webhook_lambda_zip                = "lambdas-download/webhook.zip"
  runner_binaries_syncer_lambda_zip = "lambdas-download/runner-binaries-syncer.zip"
  runners_lambda_zip                = "lambdas-download/runners.zip"

  # Runner will be available at the Github organization level
  enable_organization_runners = true

  # Additional labels you would like to add to runners (useful for workflows scheduling)
  runner_extra_labels = "ubuntu"

  # Maximum number of runners that will be created
  runners_maximum_count = 10

  # Instance size
  instance_types = ["t3.medium"]

  # Enable access to the runners via SSM (useful for troubleshooting)
  enable_ssm_on_runners = true

  # Instance bootstrapping script
  userdata_template = "./templates/user-data.sh"

  runner_run_as = "ubuntu"

  # Use custom AMI
  ami_owners = ["099720109477"] # Canonical
  ami_filter = {
    name = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  # Set the block device name for Ubuntu root device
  block_device_mappings = [{
    device_name = "/dev/sda1"
    volume_type = "gp3"
    volume_size = 20
    delete_on_termination = true
    encrypted             = false
    iops                  = null
    throughput            = null
    kms_key_id            = null
    snapshot_id           = null
  }]

  # KMS key for encrypting environment variables passed to Lambda
  kms_key_arn     = data.terraform_remote_state.keys.outputs.aws_kms_key_arn

  # Uncommet idle config to have idle runners from 9 to 5 in time zone Amsterdam
  # idle_config = [{
  #   cron      = "* * 9-17 * * *"
  #   timeZone  = "Europe/Amsterdam"
  #   idleCount = 1
  # }]

  tags = local.tags
}
