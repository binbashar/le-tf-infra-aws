#===========================================#
# Compute backend                           #
#===========================================#
variable "compute_type" {
  description = <<-EOT
    Backend of the AWS Batch compute environment. This is the switch between Fargate and EC2:
      - FARGATE      : serverless, on-demand Fargate capacity (default).
      - FARGATE_SPOT : serverless, Fargate Spot capacity.
      - EC2          : managed EC2 On-Demand instances (set ec2_config.gpu_enabled = true for GPU).
      - SPOT         : managed EC2 Spot instances.
    Job definitions follow this value automatically (platform capabilities, network and log settings).
  EOT
  type        = string
  default     = "FARGATE"

  validation {
    condition     = contains(["FARGATE", "FARGATE_SPOT", "EC2", "SPOT"], var.compute_type)
    error_message = "compute_type must be one of FARGATE, FARGATE_SPOT, EC2 or SPOT."
  }
}

variable "max_vcpus" {
  description = "Maximum vCPUs of the compute environment. Size it to (jobs running at the same time) x (vCPUs per job)."
  type        = number
  default     = 4

  validation {
    condition     = var.max_vcpus > 0
    error_message = "max_vcpus must be greater than 0."
  }
}

variable "compute_environment_update_policy" {
  description = "Optional update policy of the compute environment: how long running jobs may keep running when the environment is updated, and whether to terminate them."
  type = object({
    job_execution_timeout_minutes = number
    terminate_jobs_on_update      = optional(bool, false)
  })
  default = null
}

#===========================================#
# Networking                                #
#===========================================#
variable "subnets_tier" {
  description = <<-EOT
    Which subnets of the account VPC (base-network layer) the compute environment uses: "private" or "public".
    Private subnets need egress to ECR, CloudWatch Logs, ECS and (if used) Secrets Manager / SSM, either through a
    NAT Gateway or VPC endpoints. Both are disabled by default in apps-devstg, see README.md.
  EOT
  type        = string
  default     = "private"

  validation {
    condition     = contains(["private", "public"], var.subnets_tier)
    error_message = "subnets_tier must be either \"private\" or \"public\"."
  }
}

variable "assign_public_ip" {
  description = "Fargate only: assign a public IP to job tasks. Needed to pull images when running in public subnets without VPC endpoints."
  type        = bool
  default     = false
}

variable "additional_security_group_ids" {
  description = "Extra security groups attached to the compute environment, besides the one this layer creates (egress-only)."
  type        = list(string)
  default     = []
}

#===========================================#
# EC2 compute settings (EC2 / SPOT only)    #
#===========================================#
variable "ec2_config" {
  description = <<-EOT
    Settings used only when compute_type is EC2 or SPOT. Ignored for Fargate.
      instance_types       : instance types or families, e.g. ["optimal"], ["c6i", "m6i"] or ["g4dn.xlarge"] for GPU.
      min_vcpus            : keep at 0 so instances shut down when no jobs are running.
      allocation_strategy  : null picks BEST_FIT_PROGRESSIVE (EC2) or SPOT_PRICE_CAPACITY_OPTIMIZED (SPOT).
      bid_percentage       : SPOT only, max % of the On-Demand price (null = up to 100%).
      gpu_enabled          : use the ECS GPU-optimized AMI (NVIDIA drivers + container toolkit) unless image_type is set.
      image_type           : Batch AMI image type, null picks ECS_AL2023 or ECS_AL2023_NVIDIA (when gpu_enabled).
      image_id_override    : custom AMI ID (optional).
      root_volume_size_gib : root EBS volume size, increase it for large GPU images and datasets.
      root_volume_type     : root EBS volume type.
      ebs_kms_key_arn      : KMS key for the root volume. null uses the AWS managed aws/ebs key.
                             See README.md before using the account CMK (key policy prerequisite).
      metadata_hop_limit   : IMDSv2 hop limit. 1 keeps containers from reading the instance role through IMDS.
      enable_ssm           : attach AmazonSSMManagedInstanceCore to the instance role, for troubleshooting.
      ec2_key_pair         : optional EC2 key pair name.
  EOT
  type = object({
    instance_types       = optional(list(string), ["optimal"])
    min_vcpus            = optional(number, 0)
    allocation_strategy  = optional(string)
    bid_percentage       = optional(number)
    gpu_enabled          = optional(bool, false)
    image_type           = optional(string)
    image_id_override    = optional(string)
    root_volume_size_gib = optional(number, 30)
    root_volume_type     = optional(string, "gp3")
    ebs_kms_key_arn      = optional(string)
    metadata_hop_limit   = optional(number, 1)
    enable_ssm           = optional(bool, true)
    ec2_key_pair         = optional(string)
  })
  default = {}

  validation {
    condition     = var.ec2_config.min_vcpus >= 0
    error_message = "ec2_config.min_vcpus must be 0 or greater."
  }

  validation {
    condition     = var.ec2_config.bid_percentage == null || try(var.ec2_config.bid_percentage > 0 && var.ec2_config.bid_percentage <= 100, false)
    error_message = "ec2_config.bid_percentage must be between 1 and 100."
  }
}

#===========================================#
# Job queue                                 #
#===========================================#
variable "job_queue" {
  description = <<-EOT
    Job queue settings.
      priority                     : queue priority (higher runs first when queues share a compute environment).
      state                        : ENABLED or DISABLED.
      job_state_time_limit_actions : optional map of actions for jobs stuck in RUNNABLE, e.g.
        { insufficient_capacity = { max_time_seconds = 3600, reason = "CAPACITY:INSUFFICIENT_INSTANCE_CAPACITY" } }
  EOT
  type = object({
    priority = optional(number, 1)
    state    = optional(string, "ENABLED")
    job_state_time_limit_actions = optional(map(object({
      action           = optional(string, "CANCEL")
      max_time_seconds = number
      reason           = string
      state            = optional(string, "RUNNABLE")
    })), {})
  })
  default = {}

  validation {
    condition     = contains(["ENABLED", "DISABLED"], var.job_queue.state)
    error_message = "job_queue.state must be ENABLED or DISABLED."
  }
}

#===========================================#
# Job definitions                           #
#===========================================#
variable "job_definitions" {
  description = <<-EOT
    Map of job definitions. The map key is used in the job definition name (<project>-<env>-batch-demoapp-<key>).
    When several jobs share an image, keep one job definition and override the command per job or schedule.
      image                      : container image (ECR URI recommended).
      command                    : default command, can be overridden on submit / per schedule.
      vcpu                       : vCPUs per job. Fargate accepts 0.25, 0.5, 1, 2, 4, 8, 16; EC2 needs whole numbers.
      memory_mib                 : memory per job in MiB (must be a valid Fargate combination when using Fargate).
      gpu                        : GPUs per job, EC2 / SPOT only.
      environment                : plain environment variables.
      secrets                    : env var name => Secrets Manager secret ARN or SSM parameter ARN.
      timeout_seconds            : job attempt timeout (minimum 60).
      retry_attempts             : attempts in total (1-10).
      retry_on_host_termination  : retry when the host is terminated (Spot interruption), exit otherwise.
      fargate_platform_version   : Fargate platform version.
      cpu_architecture           : Fargate only, X86_64 or ARM64.
      ephemeral_storage_gib      : Fargate only, 21-200 GiB.
      propagate_tags             : propagate job definition tags to the ECS task.
  EOT
  type = map(object({
    image                     = string
    command                   = optional(list(string), [])
    vcpu                      = number
    memory_mib                = number
    gpu                       = optional(number, 0)
    environment               = optional(map(string), {})
    secrets                   = optional(map(string), {})
    timeout_seconds           = optional(number, 3600)
    retry_attempts            = optional(number, 1)
    retry_on_host_termination = optional(bool, true)
    fargate_platform_version  = optional(string, "LATEST")
    cpu_architecture          = optional(string, "X86_64")
    ephemeral_storage_gib     = optional(number)
    propagate_tags            = optional(bool, true)
  }))

  # The AWS Batch "Hello World" sample job (AWS Batch getting started tutorial).
  default = {
    hello-world = {
      image      = "public.ecr.aws/amazonlinux/amazonlinux:latest"
      command    = ["echo", "hello world"]
      vcpu       = 1
      memory_mib = 2048
    }
  }

  validation {
    condition     = alltrue([for k, v in var.job_definitions : v.timeout_seconds >= 60])
    error_message = "timeout_seconds must be at least 60 seconds."
  }

  validation {
    condition     = alltrue([for k, v in var.job_definitions : v.retry_attempts >= 1 && v.retry_attempts <= 10])
    error_message = "retry_attempts must be between 1 and 10."
  }

  validation {
    condition     = alltrue([for k, v in var.job_definitions : contains(["X86_64", "ARM64"], v.cpu_architecture)])
    error_message = "cpu_architecture must be X86_64 or ARM64."
  }

  validation {
    condition     = alltrue([for k, v in var.job_definitions : v.ephemeral_storage_gib == null || try(v.ephemeral_storage_gib >= 21 && v.ephemeral_storage_gib <= 200, false)])
    error_message = "ephemeral_storage_gib must be between 21 and 200."
  }

  validation {
    condition     = alltrue([for k, v in var.job_definitions : v.gpu == 0 || contains(["EC2", "SPOT"], var.compute_type)])
    error_message = "GPU jobs (gpu > 0) need compute_type EC2 or SPOT; Fargate has no GPUs."
  }

  validation {
    condition     = alltrue([for k, v in var.job_definitions : floor(v.vcpu) == v.vcpu || contains(["FARGATE", "FARGATE_SPOT"], var.compute_type)])
    error_message = "EC2 / SPOT job definitions need a whole number of vCPUs."
  }

  validation {
    condition     = alltrue(flatten([for k, v in var.job_definitions : [for name, arn in v.secrets : can(regex("^arn:aws[a-z-]*:(secretsmanager|ssm):", arn))]]))
    error_message = "Every secret must be a Secrets Manager secret ARN or an SSM parameter ARN."
  }
}

#===========================================#
# Job IAM role (least privilege)            #
#===========================================#
variable "job_role_permissions" {
  description = <<-EOT
    Permissions of the job role (the role the job's code runs with).
      s3_read_bucket_arns  : buckets the jobs can read (s3:GetObject, s3:ListBucket).
      s3_write_bucket_arns : buckets the jobs can read and write (adds s3:PutObject, s3:DeleteObject).
      kms_key_arns         : KMS keys the jobs can use (e.g. bucket encryption keys).
      managed_policy_arns  : extra IAM policies to attach.
  EOT
  type = object({
    s3_read_bucket_arns  = optional(list(string), [])
    s3_write_bucket_arns = optional(list(string), [])
    kms_key_arns         = optional(list(string), [])
    managed_policy_arns  = optional(list(string), [])
  })
  default = {}
}

#===========================================#
# Logging                                   #
#===========================================#
variable "log_retention_days" {
  description = "Retention in days of the CloudWatch log group that receives the jobs' logs."
  type        = number
  default     = 14
}

variable "log_group_kms_encryption" {
  description = "Encrypt the jobs' log group with the account KMS key (security-keys layer)."
  type        = bool
  default     = true
}

#===========================================#
# Scheduler                                 #
#===========================================#
variable "schedules" {
  description = <<-EOT
    EventBridge Scheduler schedules that submit jobs to the job queue. The map key is used in the schedule name.
      job_definition      : key of var.job_definitions to run.
      schedule_expression : cron(...), rate(...) or at(...), e.g. "cron(0 3 1 */3 ? *)" (quarterly).
      timezone            : schedule time zone.
      enabled             : ENABLED/DISABLED state of the schedule.
      command             : optional command override (e.g. one schedule per client).
      environment         : optional extra environment variables for this run.
      description         : optional description.
  EOT
  type = map(object({
    job_definition      = string
    schedule_expression = string
    timezone            = optional(string, "UTC")
    enabled             = optional(bool, true)
    command             = optional(list(string))
    environment         = optional(map(string), {})
    description         = optional(string)
  }))
  default = {}

  validation {
    condition     = alltrue([for k, v in var.schedules : contains(keys(var.job_definitions), v.job_definition)])
    error_message = "Each schedule's job_definition must be a key of var.job_definitions."
  }
}

#===========================================#
# Failure notifications                     #
#===========================================#
variable "failure_notifications" {
  description = <<-EOT
    EventBridge rule that sends job state changes of this layer's job queue to an SNS topic (Slack).
      enabled       : create the rule.
      statuses      : job statuses to notify (FAILED by default).
      sns_topic_arn : target topic. null uses the workload-monitoring topic of the notifications layer
                      (output sns_topic_arn_workload_monitoring, which allows EventBridge to publish).
  EOT
  type = object({
    enabled       = optional(bool, true)
    statuses      = optional(list(string), ["FAILED"])
    sns_topic_arn = optional(string)
  })
  default = {}
}
