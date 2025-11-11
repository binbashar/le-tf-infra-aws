# ECS Demo Applications - GitOps Deployment

This layer demonstrates a production-ready ECS deployment pattern using **GitOps principles** with dynamic image version management through AWS Systems Manager Parameter Store.

## 📋 Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Key Features](#key-features)
- [Configuration](#configuration)
- [Deployment Strategies](#deployment-strategies)
- [GitOps Workflow](#gitops-workflow)
- [Adding New Services](#adding-new-services)
- [Troubleshooting](#troubleshooting)

## Overview

This layer implements:
- **Multi-service ECS cluster** with Fargate compute
- **Application Load Balancer** with intelligent routing
- **GitOps-driven deployments** using SSM Parameter Store
- **Blue-Green and Rolling deployment** strategies
- **Internal DNS resolution** via Route 53
- **Security best practices** with IAM roles and security groups

### Demo Application: Emojivoto

The default configuration deploys the [Emojivoto](https://github.com/BuoyantIO/emojivoto) microservices application:
- **web**: Frontend service (HTTP on port 8080)
- **voting-api**: Voting backend (gRPC on port 8081)
- **emoji-api**: Emoji backend (gRPC on port 8082)
- **vote-bot**: Load generator (non-essential sidecar)

> **Note**: These are reference services. You can define any number of services and containers for your use case.

## Architecture

### Layer Structure

```
ecs-demoapps/
├── config.tf              # Provider and backend configuration
├── common-variables.tf    # Symlinked shared variables
├── locals.tf              # Dynamic SSM parameter lookups and computed values
├── variables.tf           # Service and routing definitions (single source of truth)
├── ecs.tf                 # ECS cluster and service definitions
├── alb.tf                 # Application Load Balancer and target groups
├── iam.tf                 # IAM roles for blue-green deployments
├── outputs.tf             # Layer outputs
└── README.md              # This file
```

### Component Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    Route 53 (Internal DNS)                  │
│      emojivoto.ecs.devstg.domain.com → ALB                  │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│              Application Load Balancer (ALB)                │
│  • HTTP/HTTPS listeners (80, 443)                           │
│  • Test listeners for blue-green (8080, 8443)               │
│  • Host-based routing rules                                 │
│  • Primary + secondary target groups                        │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                  ECS Fargate Services                       │
│                                                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │ emojivoto-web│  │emojivoto-svc │  │emojivoto-api │     │
│  │              │  │              │  │              │     │
│  │  web:v12     │  │ voting-api   │  │  emoji-api   │     │
│  │  vote-bot    │  │              │  │              │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
│                                                             │
│  Image versions dynamically fetched from SSM parameters    │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│               AWS Systems Manager Parameter Store           │
│  /ecs/devstg/emojivoto-web/web/image-tag = "v12"          │
│  /ecs/devstg/emojivoto-web/vote-bot/image-tag = "v12"     │
│  /ecs/devstg/emojivoto-svc/voting-api/image-tag = "v12"   │
│  /ecs/devstg/emojivoto-api/emoji-api/image-tag = "v12"    │
└─────────────────────────────────────────────────────────────┘
```

## Key Features

### 1. Variable-Driven Configuration

**All service and routing configurations** are defined as **variables** in [variables.tf](variables.tf#L18-L171), providing a single source of truth:

- `service_definitions` - Complete service and container specifications
- `routing` - ALB routing and health check configurations
- `ecs_deployment_type` - Deployment strategy selection

This design allows:
- ✅ Easy customization via `.tfvars` files or Terraform Cloud/Atlantis
- ✅ Clear separation between infrastructure code and configuration
- ✅ Reusable patterns across environments

### 2. Dynamic Image Version Management

Image versions are **never hardcoded** in Terraform. Instead:

1. **Parameter Store** holds the current version for each container:
   ```
   /ecs/{environment}/{service_name}/{container_name}/image-tag
   ```

2. **OpenTofu data sources** dynamically fetch versions (see [locals.tf](locals.tf#L125-L128)):
   ```hcl
   data "aws_ssm_parameter" "image_tags" {
     for_each = local.parameter_paths
     name     = each.value
   }
   ```

3. **Container definitions** inject versions at runtime ([locals.tf](locals.tf#L131-L144)):
   ```hcl
   image = "${container_config.image}:${container_config.version}"
   ```

### 3. Deployment Flexibility

Choose between two deployment strategies via the `ecs_deployment_type` variable:

- **ROLLING** (default) - Incremental task replacement with 50% minimum healthy
- **BLUE_GREEN** - Zero-downtime deployments with 100% capacity maintained

See [Deployment Strategies](#deployment-strategies) for details.

### 4. Intelligent Load Balancing

The ALB module ([alb.tf](alb.tf)) automatically creates:
- Primary target groups for all exposed containers
- Secondary target groups (with `-bg` suffix) for blue-green deployments
- Host-based routing rules mapping subdomains to containers
- Health checks with configurable matchers

### 5. Security Best Practices

- **IAM roles**: Separate task and execution roles per service
- **Security groups**: Least-privilege ingress rules (only from ALB)
- **Internal ALB**: Not exposed to the internet
- **Encryption**: TLS 1.3 with modern cipher suites
- **NAT Gateway validation**: Ensures outbound internet access

## Configuration

### Service Definitions

Define services in [variables.tf](variables.tf#L18-L128):

```hcl
variable "service_definitions" {
  type = map(object({
    cpu    = number
    memory = number
    containers = map(object({
      image        = string
      cpu          = number
      memory       = number
      environment  = optional(map(string), {})
      ports        = optional(map(number), {})
      entrypoint   = optional(list(string), [])
      dependencies = optional(list(object({
        containerName = string
        condition     = string
      })), [])
      essential = optional(bool, true)
    }))
  }))
}
```

### Routing Configuration

Define ALB routing in [variables.tf](variables.tf#L133-L171):

```hcl
variable "routing" {
  type = map(map(object({
    subdomain        = string
    port             = number
    protocol_version = optional(string, "HTTP1")
    health_check     = optional(object({
      matcher = optional(string)
    }), {})
  })))
}
```

### Container Configuration Options

| Option | Required | Description | Example |
|--------|----------|-------------|---------|
| `image` | ✅ | Container image (without tag) | `"123456789.dkr.ecr.us-east-1.amazonaws.com/my-app"` |
| `cpu` | ✅ | CPU units (1024 = 1 vCPU) | `512` |
| `memory` | ✅ | Memory in MB | `2048` |
| `environment` | ⬜ | Environment variables | `{ API_KEY = "value" }` |
| `ports` | ⬜ | Port mappings | `{ http = 8080 }` |
| `entrypoint` | ⬜ | Custom entrypoint | `["node", "server.js"]` |
| `dependencies` | ⬜ | Container dependencies | `[{ containerName = "db", condition = "HEALTHY" }]` |
| `essential` | ⬜ | Critical to task success (default: `true`) | `false` |

### Routing Configuration Options

| Option | Required | Description | Example |
|--------|----------|-------------|---------|
| `subdomain` | ✅ | DNS subdomain (under environment domain) | `"my-api.ecs"` |
| `port` | ✅ | Container port to route to | `8080` |
| `protocol_version` | ⬜ | Target group protocol (default: `HTTP1`) | `"GRPC"` |
| `health_check.matcher` | ⬜ | Expected HTTP status codes | `"200"` or `"200-404"` |

## Deployment Strategies

### Rolling Deployment (Default)

**Strategy**: Gradually replaces tasks with new versions.

**Configuration**:
```hcl
ecs_deployment_type = "ROLLING"
```

**Behavior**:
- Minimum healthy percent: **50%**
- Maximum percent: **200%**
- Target groups: Primary only
- Listeners: HTTP (80) → HTTPS (443)

**Use when**:
- Cost optimization is priority
- Brief downtime is acceptable
- Simpler infrastructure is preferred

### Blue-Green Deployment

**Strategy**: Maintains two identical environments and instantly switches traffic.

**Configuration**:
```hcl
ecs_deployment_type = "BLUE_GREEN"
```

**Behavior**:
- Minimum healthy percent: **100%**
- Maximum percent: **200%**
- Target groups: Primary + secondary (`-bg` suffix)
- Listeners:
  - Production: HTTP (80) → HTTPS (443)
  - Test: HTTP (8080) → HTTPS (8443)
- Bake time: **5 minutes**
- Automatic rollback on failure

**Use when**:
- Zero downtime is critical
- Instant rollback capability needed
- Testing new versions before production traffic shift

### Target Group Configuration

**Rolling Deployment:**
```
ecs-web              (primary)
ecs-voting-api       (primary)
ecs-emoji-api        (primary)
```

**Blue-Green Deployment:**
```
ecs-web              (production)
ecs-web-bg           (test/new version)
ecs-voting-api       (production)
ecs-voting-api-bg    (test/new version)
ecs-emoji-api        (production)
ecs-emoji-api-bg     (test/new version)
```

## GitOps Workflow

### 1. Initial Setup

Create SSM parameters for all containers defined in `service_definitions`:

```bash
# Get environment name
ENVIRONMENT="devstg"

# For each service and container, create parameter
aws ssm put-parameter \
  --name "/ecs/${ENVIRONMENT}/emojivoto-web/web/image-tag" \
  --value "v12" \
  --type "String" \
  --description "Image tag for emojivoto-web web container"

aws ssm put-parameter \
  --name "/ecs/${ENVIRONMENT}/emojivoto-web/vote-bot/image-tag" \
  --value "v12" \
  --type "String" \
  --description "Image tag for emojivoto-web vote-bot container"

# Repeat for all containers...
```

**Parameter Naming Convention**:
```
/ecs/{environment}/{service_name}/{container_name}/image-tag
```

### 2. Application Development Cycle

```
┌─────────────────────────────────────────────────────────────┐
│  Developer commits code                                      │
└───────────────────┬─────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────────────────────┐
│  CI/CD pipeline:                                             │
│  1. Build container image                                    │
│  2. Tag with commit SHA or version                           │
│  3. Push to ECR                                              │
└───────────────────┬─────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────────────────────┐
│  CI/CD updates SSM parameter:                                │
│  aws ssm put-parameter \                                     │
│    --name "/ecs/devstg/my-service/api/image-tag" \          │
│    --value "${GITHUB_SHA}" \                                 │
│    --overwrite                                               │
└───────────────────┬─────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────────────────────┐
│  OpenTofu detects parameter change (next apply/plan)        │
└───────────────────┬─────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────────────────────┐
│  ECS service updates task definition with new image          │
│  Deployment executes based on strategy (rolling/blue-green) │
└─────────────────────────────────────────────────────────────┘
```

### 3. Example CI/CD Integration

**GitHub Actions**:
```yaml
- name: Update SSM Parameter
  run: |
    aws ssm put-parameter \
      --name "/ecs/${{ env.ENVIRONMENT }}/${{ env.SERVICE }}/${{ env.CONTAINER }}/image-tag" \
      --value "${{ github.sha }}" \
      --overwrite
```

**GitLab CI**:
```yaml
deploy:
  script:
    - aws ssm put-parameter
        --name "/ecs/${ENVIRONMENT}/${SERVICE}/${CONTAINER}/image-tag"
        --value "${CI_COMMIT_SHA}"
        --overwrite
```

### 4. Monitoring Deployments

```bash
# Check current parameter values
aws ssm get-parameters-by-path \
  --path "/ecs/devstg/" \
  --recursive

# Check ECS service status
aws ecs describe-services \
  --cluster bb-devstg-demoapps-cluster \
  --services emojivoto-web

# Check task definition version
aws ecs describe-task-definition \
  --task-definition bb-devstg-demoapps-emojivoto-web
```

## Adding New Services

### Step 1: Define the Service

Add to `service_definitions` variable in [variables.tf](variables.tf) or a `.tfvars` file:

```hcl
service_definitions = {
  # Existing services...

  my-new-service = {
    cpu    = 1024
    memory = 4096

    containers = {
      api = {
        image  = "123456789.dkr.ecr.us-east-1.amazonaws.com/my-api"
        cpu    = 512
        memory = 2048

        environment = {
          API_PORT = "8000"
          LOG_LEVEL = "info"
        }

        ports = {
          http = 8000
        }
      }

      worker = {
        image  = "123456789.dkr.ecr.us-east-1.amazonaws.com/my-worker"
        cpu    = 512
        memory = 2048

        environment = {
          QUEUE_URL = "https://sqs.us-east-1.amazonaws.com/account/queue"
        }

        essential = false  # Non-critical sidecar
      }
    }
  }
}
```

### Step 2: Configure Routing

Add to `routing` variable (only for containers needing external access):

```hcl
routing = {
  # Existing routes...

  my-new-service = {
    api = {
      subdomain = "my-api.ecs"  # Creates my-api.ecs.devstg.domain.com
      port      = 8000
      health_check = {
        matcher = "200"
      }
    }
  }
}
```

### Step 3: Create SSM Parameters

**Critical**: Create parameters for **ALL** containers:

```bash
# For containers WITH routing (exposed via ALB)
aws ssm put-parameter \
  --name "/ecs/devstg/my-new-service/api/image-tag" \
  --value "v1.0.0" \
  --type "String"

# For containers WITHOUT routing (internal sidecars)
aws ssm put-parameter \
  --name "/ecs/devstg/my-new-service/worker/image-tag" \
  --value "v1.0.0" \
  --type "String"
```

### Step 4: Apply Changes

```bash
cd apps-devstg/us-east-1/ecs-demoapps

# Initialize if first time
leverage tf init

# Plan to verify
leverage tf plan

# Apply changes
leverage tf apply
```

### Step 5: Verify Deployment

```bash
# Check service is running
aws ecs describe-services \
  --cluster bb-devstg-demoapps-cluster \
  --services my-new-service

# Test DNS resolution
dig my-api.ecs.devstg.domain.com

# Test endpoint
curl https://my-api.ecs.devstg.domain.com/health
```

## Troubleshooting

### ⚠️ GLIBC Compatibility Issue

The base Emojivoto images have GLIBC version dependencies. You may encounter:

```
emojivoto-vote-bot: /lib/x86_64-linux-gnu/libc.so.6: version 'GLIBC_2.32' not found
emojivoto-vote-bot: /lib/x86_64-linux-gnu/libc.so.6: version 'GLIBC_2.34' not found
```

**Solution**: Use pre-built compatible images:

```bash
# Pull compatible images
docker pull docker.l5d.io/buoyantio/emojivoto-emoji-svc:v12
docker pull docker.l5d.io/buoyantio/emojivoto-voting-svc:v12
docker pull docker.l5d.io/buoyantio/emojivoto-web:v12

# Tag for your ECR repository
docker tag docker.l5d.io/buoyantio/emojivoto-emoji-svc:v12 \
  <aws-account-id>.dkr.ecr.<region>.amazonaws.com/demo-emojivoto/emoji-svc:v12

docker tag docker.l5d.io/buoyantio/emojivoto-voting-svc:v12 \
  <aws-account-id>.dkr.ecr.<region>.amazonaws.com/demo-emojivoto/voting-svc:v12

docker tag docker.l5d.io/buoyantio/emojivoto-web:v12 \
  <aws-account-id>.dkr.ecr.<region>.amazonaws.com/demo-emojivoto/web:v12

# Authenticate to ECR
aws ecr get-login-password --region <region> | \
  docker login --username AWS --password-stdin <aws-account-id>.dkr.ecr.<region>.amazonaws.com

# Push to ECR
docker push <aws-account-id>.dkr.ecr.<region>.amazonaws.com/demo-emojivoto/emoji-svc:v12
docker push <aws-account-id>.dkr.ecr.<region>.amazonaws.com/demo-emojivoto/voting-svc:v12
docker push <aws-account-id>.dkr.ecr.<region>.amazonaws.com/demo-emojivoto/web:v12
```

### Missing SSM Parameters

**Error**: `InvalidParameter: parameter /ecs/devstg/service/container/image-tag not found`

**Solution**: Create the missing parameter:
```bash
aws ssm put-parameter \
  --name "/ecs/devstg/service/container/image-tag" \
  --value "latest" \
  --type "String"
```

### NAT Gateway Not Available

**Error**: `Make sure a NAT Gateway is up before deploying the ECS cluster`

**Solution**: Deploy the NAT Gateway in the `base-network` layer:
```bash
cd apps-devstg/us-east-1/base-network
leverage tf apply
```

### Service Fails to Start

Check CloudWatch logs:
```bash
# Get log group name
aws logs describe-log-groups --log-group-name-prefix /ecs/devstg

# Stream logs
aws logs tail /ecs/devstg/service-name --follow
```

### Blue-Green Deployment Stuck

**Issue**: Deployment waiting on test traffic validation

**Check**:
1. Test listener (port 8443) is accessible
2. Health checks are passing on `-bg` target groups
3. Bake time (5 minutes) has elapsed

**Force completion**:
```bash
# Continue deployment manually
aws deploy continue-deployment \
  --deployment-id <deployment-id>
```

## References

- [Binbash Leverage Documentation](https://leverage.binbash.co)
- [AWS ECS Blue/Green Deployments](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/deployment-type-bluegreen.html)
- [ECS Task Definition Parameters](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html)
- [ALB Target Groups](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-target-groups.html)
- [Emojivoto Demo Application](https://github.com/BuoyantIO/emojivoto)

## Module Versions

- **ECS Module**: `github.com/binbashar/terraform-aws-ecs.git?ref=v6.7.0`
- **ALB Module**: `github.com/binbashar/terraform-aws-alb.git?ref=v10.0.2`
- **OpenTofu**: `~> 1.6.6`
- **AWS Provider**: `~> 5.100`

---

**Layer**: `apps-devstg/us-east-1/ecs-demoapps`
**Last Updated**: 2025-11-11
**Maintained by**: Binbash Leverage Team
