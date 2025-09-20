# ECS Demo App

## ⚠️ GLIBC Compatibility Issue

The base image provided by `emijivoto` has a known dependency issue related to GLIBC versions. When deploying the microservices (MS) images to ECS, you might encounter errors such as:

```bash
emojivoto-vote-bot: /lib/x86_64-linux-gnu/libc.so.6: version 'GLIBC_2.32' not found (required by emojivoto-vote-bot)

emojivoto-vote-bot: /lib/x86_64-linux-gnu/libc.so.6: version 'GLIBC_2.34' not found (required by emojivoto-vote-bot)
```

## Workaround

To gracefully avoid these errors, use the already built images:

```bash
docker pull docker.l5d.io/buoyantio/emojivoto-emoji-svc:v12

docker pull docker.l5d.io/buoyantio/emojivoto-voting-svc:v12

docker pull docker.l5d.io/buoyantio/emojivoto-web:v12
```

### Tag the images to fit repository naming:

```bash
docker tag docker.l5d.io/buoyantio/emojivoto-emoji-svc:v12 <aws-account-id>.dkr.ecr.<region>.amazonaws.com/ emoji-svc:latest

docker tag docker.l5d.io/buoyantio/emojivoto-voting-svc:v12 <aws-account-id>.dkr.ecr.<region>.amazonaws.com/ voting-svc:latest

docker tag docker.l5d.io/buoyantio/emojivoto-web:v12 <aws-account-id>.dkr.ecr.<region>.amazonaws.com/ web:latest
```

### Push to ECR repository:

```bash
docker push <aws-account-id>.dkr.ecr.<region>.amazonaws.com/ emoji-svc:latest

docker push <aws-account-id>.dkr.ecr.<region>.amazonaws.com/ voting-svc:latest

docker push <aws-account-id>.dkr.ecr.<region>.amazonaws.com/ web:latest
```

After pushing images to your ECR, proceed with your deployment pipeline to ECS.

## 📋 Service Configuration Guide

### Current Service Structure

The `emojivoto` service (reference implementation) contains:
- **web**: Frontend service (port 8080)
- **voting-api**: Voting backend service (port 8081, gRPC)
- **emoji-api**: Emoji backend service (port 8082, gRPC)
- **vote-bot**: Load generator (depends on web)

**Note**: These are reference services only. You can define any number of services and containers for your use case.

### Adding New Services

To add a new service, update the `service_definitions` in `locals.tf`:

```hcl
service_definitions = {
  # Existing emojivoto service...

  my-new-service = {
    cpu    = 1024
    memory = 4096

    containers = {
      api = {
        image   = "my-registry/my-api"
        cpu     = 512
        memory  = 2048

        environment = {
          API_PORT = 8000
        }

        ports = {
          http = 8000
        }
      }

      worker = {
        image   = "my-registry/my-worker"
        cpu     = 512
        memory  = 2048

        environment = {
          QUEUE_URL = "https://sqs.region.amazonaws.com/account/queue"
        }

        essential = false
      }
    }
  }
}
```

### Parameter Store Requirements

**Critical**: For each container, you MUST create corresponding Parameter Store parameters:

#### Parameter Naming Convention
```
/ecs/{environment}/{service_name}/{container_name}/image-tag
```

#### Required Parameters for New Service
Based on the example above, create these parameters:

```bash
# For my-new-service
aws ssm put-parameter \
  --name "/ecs/devstg/my-new-service/api/image-tag" \
  --value "v1.0.0" \
  --type "String" \
  --description "Image tag for my-new-service api container"

aws ssm put-parameter \
  --name "/ecs/devstg/my-new-service/worker/image-tag" \
  --value "v1.0.0" \
  --type "String" \
  --description "Image tag for my-new-service worker container"
```

### Container Configuration Options

Each container supports these configuration options:

```hcl
container_name = {
  image       = "registry/image-name"          # Required: Container image
  cpu         = 512                           # Required: CPU units (1024 = 1 vCPU)
  memory      = 2048                          # Required: Memory in MB

  # Optional configurations
  environment = {                             # Environment variables
    KEY = "value"
  }

  ports = {                                   # Port mappings
    port_name = port_number
  }

  entrypoint = ["command", "arg1"]            # Custom entrypoint

  dependencies = [{                           # Container dependencies
    containerName = "other-container"
    condition     = "START"                   # START, COMPLETE, SUCCESS, HEALTHY
  }]

  essential = true                            # Default: true. Set false for non-critical containers
}
```

### Routing Configuration

For containers that need external access, add routing configuration:

```hcl
routing = {
  my-new-service = {
    api = {
      subdomain = "my-api.ecs"                # Creates my-api.ecs.devstg.domain.com
      port      = 8000
      health_check = {
        matcher = "200"                       # Expected HTTP response codes
      }
    }
  }
}
```

### GitOps Workflow

#### 1. Application Development
1. Build and test your application
2. Push container image to ECR with new tag (e.g., commit SHA)
3. Update Parameter Store with new image tag
4. Infrastructure automatically detects and deploys

#### 2. Parameter Store Update (via CI/CD)
```bash
# Application CI/CD pipeline updates parameter
aws ssm put-parameter \
  --name "/ecs/devstg/my-service/container/image-tag" \
  --value "$GITHUB_SHA" \
  --overwrite
```

#### 3. Infrastructure Response
- Terraform data source detects parameter change
- ECS service updates task definition with new image
- Blue-green deployment (if configured) or rolling update

### Important Notes

#### Parameter Store Requirements
- **All containers** defined in `service_definitions` MUST have corresponding Parameter Store parameters
- Parameter paths follow strict convention: `/ecs/{environment}/{service}/{container}/image-tag`
- Missing parameters will cause Terraform failures

#### Image Version Management
- Never hardcode image versions in the Terraform code
- All versions are dynamically fetched from Parameter Store
- Applications control deployment timing through parameter updates