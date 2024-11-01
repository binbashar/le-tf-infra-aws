module "database_migration_service" {
  source = "github.com/binbashar/terraform-aws-dms?ref=v2.3.0"

  # Subnet group
  repl_subnet_group_name        = "${local.name}-subnet-group"
  repl_subnet_group_description = "${local.name} Subnet group"
  repl_subnet_group_subnet_ids  = data.terraform_remote_state.vpc.outputs.private_subnets

  # DMS Instance
  repl_instance_allocated_storage            = 64
  repl_instance_auto_minor_version_upgrade   = true
  repl_instance_allow_major_version_upgrade  = true
  repl_instance_apply_immediately            = true
  repl_instance_engine_version               = "3.5.2"
  repl_instance_multi_az                     = true
  repl_instance_preferred_maintenance_window = "sun:10:30-sun:14:30"
  repl_instance_publicly_accessible          = false
  repl_instance_class                        = "dms.t3.large"
  repl_instance_id                           = local.name
  repl_instance_vpc_security_group_ids       = [module.replication_instance_security_group.security_group_id]

  endpoints = {
    # source_apps_devstg_aurora_pgsql = {
    #   database_name               = "example"
    #   endpoint_id                 = "example-source-aurora-pgslq"
    #   endpoint_type               = "source"
    #   engine_name                 = "aurora-postgresql"
    #   extra_connection_attributes = "heartbeatFrequency=1;"
    #   username                    = "postgresqlUser"
    #   password                    = "youShouldPickABetterPassword123!"
    #   port                        = 5432
    #   server_name                 = "dms-ex-src.cluster-abcdefghijkl.us-east-1.rds.amazonaws.com"
    #   ssl_mode                    = "none"
    #   tags                        = local.tags
    # }

    source_data_science_aurora_mysql = {
      database_name               = data.terraform_remote_state.aurora_mysql.outputs.demoapps_sockshop_database_name
      endpoint_id                 = data.terraform_remote_state.aurora_mysql.outputs.cluster_id
      endpoint_type               = "source"
      engine_name                 = "aurora"
      extra_connection_attributes = "heartbeatFrequency=1;"
      username                    = data.terraform_remote_state.aurora_mysql.outputs.demoapps_sockshop_username
      password                    = data.terraform_remote_state.aurora_mysql.outputs.demoapps_sockshop_password
      port                        = 3306
      server_name                 = data.terraform_remote_state.aurora_mysql.outputs.cluster_reader_endpoint
      ssl_mode                    = "none"
      tags                        = local.tags
    }
  }

  # S3 Endpoints
  s3_endpoints = {
    s3-destination = {
      endpoint_id   = "${local.name}-s3-destination"
      endpoint_type = "target"
      engine_name   = "s3"
      bucket_folder               = "destinationdata"
      bucket_name                 = module.s3_bucket_datalake.s3_bucket_id
      data_format                 = "parquet"
      ssl_mode                    = "none"
      encryption_mode             = "SSE_S3"
      extra_connection_attributes = ""
      #external_table_definition   = file("configs/s3_table_definition.json")
      tags                        = local.tags
    }
  }

  replication_tasks = {
    cdc_demo = {
      replication_task_id       = "${local.name}-replication-task"
      migration_type            = "cdc"
      replication_task_settings = file("config/task_settings.json")
      table_mappings            = file("config/table_mappings.json")
      source_endpoint_key       = "source"
      target_endpoint_key       = "destination"
      tags                      = local.tags
    }
  }

  # event_subscriptions = {
  #   instance = {
  #     name                             = "instance-events"
  #     enabled                          = true
  #     instance_event_subscription_keys = ["example"]
  #     source_type                      = "replication-instance"
  #     sns_topic_arn                    = "arn:aws:sns:us-east-1:012345678910:example-topic"
  #     event_categories                 = [
  #       "failure",
  #       "creation",
  #       "deletion",
  #       "maintenance",
  #       "failover",
  #       "low storage",
  #       "configuration change"
  #     ]
  #   }
  #   task = {
  #     name                         = "task-events"
  #     enabled                      = true
  #     task_event_subscription_keys = ["cdc_ex"]
  #     source_type                  = "replication-task"
  #     sns_topic_arn                = "arn:aws:sns:us-east-1:012345678910:example-topic"
  #     event_categories             = [
  #       "failure",
  #       "state change",
  #       "creation",
  #       "deletion",
  #       "configuration change"
  #     ]
  #   }
  # }

  tags = local.tags
}

module "replication_instance_security_group" {
  source = "github.com/binbashar/terraform-aws-security-group.git?ref=v5.1.1"

  name        = "${local.name}-replication-instance-security-group"
  description = "Security group for DataLake Replication Instance"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id

  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = -1
      description = "All egress"
      cidr_blocks = "0.0.0.0/0"
    }
  ]

  ingress_with_cidr_blocks = [
    {
      from_port   = 0 #TODO
      to_port     = 0 #TODO
      protocol    = -1
      description = "Private Subnet CIDR"
      cidr_blocks = "0.0.0.0/0" #TODO
    }
  ]
}

