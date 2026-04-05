# Tools: API Gateway Apps Proxy

## Overview

This layer deploys AWS API Gateway v2 (HTTP API) as a reverse proxy to route public traffic to private applications running behind a Network Load Balancer (NLB) in a private VPC. It's designed for multi-tenant applications where different sites need to access the same backend applications with proper host header rewriting.

## Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                          Public Internet                             │
└──────────────────┬──────────────────────────────────────────────────┘
                   │
                   │ HTTPS (public domain)
                   │ site1.dev.aws.binbash.com.ar/app/scheduler/
                   │
┌──────────────────▼──────────────────────────────────────────────────┐
│              AWS API Gateway v2 (HTTP API)                           │
│                                                                       │
│  ┌─────────────────┐         ┌─────────────────┐                   │
│  │  site1 APIGW    │         │  site2 APIGW    │                   │
│  │  Custom Domain  │         │  Custom Domain  │                   │
│  └────────┬────────┘         └────────┬────────┘                   │
│           │                           │                              │
│           │  Routes:                  │  Routes:                    │
│           │  /app/scheduler/{proxy+}  │  /app/scheduler/{proxy+}    │
│           │  /app/mbot/{proxy+}       │  /app/mbot/{proxy+}         │
│           │  /app/mbotsvc/{proxy+}    │  /app/mbotsvc/{proxy+}      │
│           │  /app/task-svc/{proxy+}   │  /app/task-svc/{proxy+}     │
└───────────┼───────────────────────────┼──────────────────────────────┘
            │                           │
            └───────────┬───────────────┘
                        │
                        │ VPC Link (shared)
                        │
┌───────────────────────▼──────────────────────────────────────────────┐
│                       Private VPC                                     │
│                                                                       │
│  ┌─────────────────────────────────────────────────────────────────┐│
│  │              Network Load Balancer (NLB)                         ││
│  │              Port 443 (HTTPS Listener)                           ││
│  └────────────────────────┬─────────────────────────────────────────┘│
│                           │                                           │
│                           │ Forwards to                              │
│                           │                                           │
│  ┌────────────────────────▼─────────────────────────────────────────┐│
│  │              NGINX Ingress Controller                             ││
│  │              (kubernetes.io/service-name:                        ││
│  │               ingress-nginx/ingress-nginx-private-controller)    ││
│  └────────────────────────┬─────────────────────────────────────────┘│
│                           │                                           │
│                           │ Routes by Host Header                    │
│                           │                                           │
│  ┌────────────────────────▼─────────────────────────────────────────┐│
│  │                    EKS Cluster Applications                       ││
│  │                                                                   ││
│  │  site1.scheduler.dev.aws.binbash.com.ar  (App: Scheduler)       ││
│  │  site1.mbot.dev.aws.binbash.com.ar       (App: MBot)            ││
│  │  site1.mbotsvc.dev.aws.binbash.com.ar    (App: MBot Service)    ││
│  │  site1.task-svc.dev.aws.binbash.com.ar   (App: Task Service)    ││
│  └───────────────────────────────────────────────────────────────────┘│
└───────────────────────────────────────────────────────────────────────┘
```

## Use Case

This solution is ideal for:
- **Multi-tenant applications** with different customer sites accessing the same backend
- **Path-based routing** to internal services without exposing internal hostnames
- **Centralized access control** and logging for multiple applications
- **Cost optimization** by sharing a single VPC Link across multiple API Gateways (VPC Link limit: 10 per account per region)

## What This Layer Provisions

### Core Resources
- **API Gateway v2 (HTTP API)**: One per site, with custom domain support
- **VPC Link**: Single shared VPC Link for all API Gateways (to stay within AWS quota)
- **Security Group**: Controls access through the VPC Link
- **Route53 Records**: Alias records for custom domains
- **CloudWatch Log Groups**: API Gateway access logs per site

### Request Transformation

The API Gateway performs the following transformations:

| Public Request | Private Request (Host Header) |
|----------------|-------------------------------|
| `site1.dev.aws.binbash.com.ar/app/scheduler/*` | `site1.scheduler.intra.dev.aws.binbash.com.ar` |
| `site1.dev.aws.binbash.com.ar/app/mbot/*` | `site1.mbot.intra.dev.aws.binbash.com.ar` |
| `site1.dev.aws.binbash.com.ar/app/mbotsvc/*` | `site1.mbotsvc.intra.dev.aws.binbash.com.ar` |
| `site1.dev.aws.binbash.com.ar/app/task-svc/*` | `site1.task-svc.intra.dev.aws.binbash.com.ar` |

Additionally, the API Gateway:
- **Strips the `/app/{app_name}` prefix** from the path
- **Adds custom headers**: `X-Client-Ip` and `X-Real-Ip` with the original client IP
- **Rewrites the Host header** to match the internal application hostname
- **Verifies TLS** using the internal domain name

## Prerequisites

### Layer Dependencies

This layer requires the following resources to be deployed first:

1. **EKS VPC** (`apps-devstg/us-east-1/k8s-eks/network/`)
   - VPC ID
   - Private subnet IDs and CIDR blocks

2. **SSL Certificates** (`apps-devstg/us-east-1/security-certs/diligentrobots.io/`)
   - ACM certificate ARN for the public domain

3. **DNS Zone** (Legacy layer: `legacy/dns/diligentrobots.io/`)
   - Route53 hosted zone ID

4. **Network Load Balancer** (Created by Kubernetes/Helm)
   - NLB with specific tags:
     - `Environment`: matches environment
     - `kubernetes.io/cluster/<cluster-name>`: "owned"
     - `kubernetes.io/service-name`: "ingress-nginx/ingress-nginx-private-controller"
   - HTTPS listener on port 443

### Check Dependencies

Before deploying, verify dependencies with:
```bash
leverage run layer_dependency
```

## Configuration

### Adding Sites

Edit `locals.tf` and add site names to the `sites` list:

```hcl
sites = [
  "site1",
  "site2",
  "site3"
]
```

Each site will get:
- Its own API Gateway with custom domain: `{site}.dev.aws.binbash.com.ar`
- Routes for all defined applications
- Dedicated CloudWatch log group

### Adding Applications

Edit `locals.tf` and add application names to the `apps` list:

```hcl
apps = [
  "scheduler",
  "mbot",
  "mbotsvc",
  "task-svc",
  "new-app"  # Add new applications here
]
```

Each application will get:
- A route on every site's API Gateway: `ANY /app/{app}/{proxy+}`
- Host header rewriting: `{site}.{app}.intra.dev.aws.binbash.com.ar`

### Domain Configuration

The domain structure is defined in `locals.tf`:

```hcl
public_domain  = "${local.env}.aws.binbash.com.ar"       # External facing
private_domain = "intra.${local.public_domain}"           # Internal routing
```

To change domains, update these locals and ensure:
- ACM certificate covers the public domain
- Route53 zone exists for the public domain
- Internal applications use the private domain pattern

## Deployment

### 1. Navigate to Layer Directory
```bash
cd apps-devstg/us-east-1/tools-apigw-apps-proxy\ --/
```

### 2. Initialize OpenTofu
```bash
leverage tf init
```

### 3. Review Configuration
Edit `locals.tf` to configure sites and apps.

### 4. Plan Changes
```bash
leverage tf plan
```

### 5. Apply Changes
```bash
leverage tf apply
```

### 6. Verify Deployment
Check the outputs for API Gateway endpoints and custom domains:
```bash
leverage tf output
```

## Security Considerations

### VPC Link Security Group

The security group allows:
- **Ingress**: All traffic (0.0.0.0/0) - Consider restricting to CloudFront IPs or specific ranges
- **Egress**: Only to EKS private subnets

**Recommendation**: Tighten ingress rules in production environments.

### CORS Configuration

Current configuration allows all origins:
```hcl
cors_configuration = {
  allow_headers     = ["*"]
  allow_methods     = ["*"]
  allow_origins     = ["*"]
  allow_credentials = "false"
  expose_headers    = ["*"]
  max_age           = 0
}
```

**Recommendation**: Restrict origins to specific domains in production.

### Throttling

API Gateway throttling is configured per site:
- **Rate limit**: 100 requests per second
- **Burst limit**: 100 requests

Adjust in `main.tf` based on your application needs:
```hcl
default_route_settings = {
  throttling_rate_limit  = 100
  throttling_burst_limit = 100
}
```

### Client IP Preservation

The original client IP is preserved in custom headers:
- `X-Client-Ip`: Original source IP
- `X-Real-Ip`: Original source IP

Applications can use these headers for:
- IP-based access control
- Logging and analytics
- Rate limiting per client

## Monitoring and Logging

### CloudWatch Logs

API Gateway access logs are stored in CloudWatch Log Groups:
- **Log Group Pattern**: `/aws/apigateway/apigw-proxy-{site}`
- **Retention**: 7 days
- **Format**: JSON with request/response details

### Log Fields

The following fields are logged:
- `httpMethod`: HTTP method (GET, POST, etc.)
- `protocol`: HTTP protocol version
- `requestTime`: Request timestamp
- `responseLength`: Response size in bytes
- `routeKey`: Matched route
- `status`: HTTP status code
- `requestId`: Unique request identifier
- `ip`: Client IP address
- `errorMessage`: Error details (if any)
- `integrationError`: Backend integration errors

### Monitoring Queries

View logs in CloudWatch:
```bash
# From AWS Console
CloudWatch → Log Groups → /aws/apigateway/apigw-proxy-site1
```

Or use CloudWatch Insights queries:
```
fields @timestamp, status, httpMethod, routeKey, ip
| filter status >= 400
| sort @timestamp desc
| limit 100
```

## Troubleshooting

### Common Issues

#### 1. VPC Link Creation Fails
**Symptom**: VPC Link stuck in "PENDING" state

**Causes**:
- Subnet IDs are invalid or not in the same VPC
- Security group doesn't allow traffic

**Solution**:
```bash
# Verify VPC and subnets
leverage tf state show data.terraform_remote_state.eks-vpc

# Check security group rules
leverage tf state show aws_security_group.this[0]
```

#### 2. 503 Service Unavailable
**Symptom**: API Gateway returns 503 errors

**Causes**:
- NLB not found or unhealthy targets
- Security group blocking traffic
- TLS verification failing

**Solution**:
```bash
# Check NLB health
aws elbv2 describe-target-health \
  --target-group-arn <target-group-arn> \
  --profile bb-apps-devstg-devops

# Verify NLB tags match the data source
aws elbv2 describe-load-balancers \
  --profile bb-apps-devstg-devops \
  --query 'LoadBalancers[*].[LoadBalancerArn,Tags]'
```

#### 3. Host Header Not Working
**Symptom**: NGINX returns 404 or routes to wrong application

**Causes**:
- Host header rewriting not working
- NGINX Ingress not configured for the internal hostname

**Solution**:
- Verify NGINX Ingress has rules for: `{site}.{app}.intra.dev.aws.binbash.com.ar`
- Check API Gateway request transformation in CloudWatch Logs
- Ensure internal DNS resolves correctly (if using DNS)

#### 4. Custom Domain Certificate Issues
**Symptom**: SSL/TLS errors or domain not resolving

**Causes**:
- Certificate ARN is invalid or expired
- Certificate doesn't cover the domain
- Route53 record not created

**Solution**:
```bash
# Verify certificate
leverage tf state show data.terraform_remote_state.certs

# Check Route53 record
leverage tf state show 'aws_route53_record.this["site1"]'
```

### Debug Mode

Enable detailed logging by checking CloudWatch Logs for your site:
```bash
aws logs tail /aws/apigateway/apigw-proxy-site1 --follow \
  --profile bb-apps-devstg-devops
```

## Cost Estimation

Run cost analysis before applying:
```bash
# From repository root
make infracost-breakdown
```

### Estimated Monthly Costs
- **API Gateway**: ~$1.00 per million requests + $0.09 per GB data transfer
- **VPC Link**: ~$36.00 per month (flat fee)
- **CloudWatch Logs**: ~$0.50 per GB ingested + $0.03 per GB stored
- **Route53 Records**: $0.50 per hosted zone per month

**Note**: VPC Link cost is shared across all sites, making this solution cost-effective for multiple sites.

## Examples

### Example Request Flow

```bash
# Public request
curl https://site1.dev.aws.binbash.com.ar/app/scheduler/api/v1/jobs

# API Gateway transforms to:
#   Method: GET
#   Host: site1.scheduler.intra.dev.aws.binbash.com.ar
#   Path: /api/v1/jobs
#   Headers:
#     X-Client-Ip: 203.0.113.42
#     X-Real-Ip: 203.0.113.42

# Forwarded via VPC Link → NLB → NGINX Ingress → Backend Application
```

### Adding a New Site and App

1. **Add site to locals.tf**:
```hcl
sites = [
  "site1",
  "site2",
  "newsite"  # Add new site
]
```

2. **Add app to locals.tf**:
```hcl
apps = [
  "scheduler",
  "mbot",
  "mbotsvc",
  "task-svc",
  "newapp"  # Add new app
]
```

3. **Deploy**:
```bash
leverage tf plan
leverage tf apply
```

4. **Configure backend application** with Ingress for:
   - `site1.newapp.intra.dev.aws.binbash.com.ar`
   - `site2.newapp.intra.dev.aws.binbash.com.ar`
   - `newsite.newapp.intra.dev.aws.binbash.com.ar`

5. **Test**:
```bash
curl https://site1.dev.aws.binbash.com.ar/app/newapp/health
curl https://newsite.dev.aws.binbash.com.ar/app/scheduler/health
```

## Module Reference

This layer uses the Binbash API Gateway v2 module:
- **Source**: `github.com/binbashar/terraform-aws-apigateway-v2.git?ref=v2.2.2`
- **Documentation**: [Module README](https://github.com/binbashar/terraform-aws-apigateway-v2)

## Related Layers

- **EKS Network**: `apps-devstg/us-east-1/k8s-eks/network/`
- **SSL Certificates**: `apps-devstg/us-east-1/security-certs/diligentrobots.io/`
- **DNS Zone**: Legacy layer at `legacy/dns/diligentrobots.io/`

## Additional Resources

- [AWS API Gateway v2 Documentation](https://docs.aws.amazon.com/apigateway/latest/developerguide/http-api.html)
- [VPC Links for HTTP APIs](https://docs.aws.amazon.com/apigateway/latest/developerguide/http-api-vpc-links.html)
- [Request Transformation](https://docs.aws.amazon.com/apigateway/latest/developerguide/http-api-parameter-mapping.html)
- [Leverage Documentation](https://leverage.binbash.co)
