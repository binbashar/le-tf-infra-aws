ecs_cluster_settings = {
    name = "ecs-bluegreen-cluster"
    fargate_capacity_providers = {
      FARGATE = {
        default_capacity_provider_strategy = {
          weight = 60
          base   = 1
        }
      }
      FARGATE_SPOT = {
        default_capacity_provider_strategy = {
          weight = 40
          base   = 0
        }
      }
    }
}
