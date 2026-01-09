#
# Create an API Gateway per site, each with a single stage, and with one route
# per application (app) that needs to be routed.
# The examples below show the type of transformations that the API Gateway
# needs to do in order to map a public host/path to a private one:
#  - toolsapigw.dev.binbash.com.ar/app/scheduler/     => toolsapigw.scheduler.dev.aws.binbash.com.ar
#  - toolsapigw.dev.binbash.com.ar/app/mbot/          => toolsapigw.mbot.dev.aws.binbash.com.ar
#  - toolsapigw.dev.binbash.com.ar/app/mbotsvc/       => toolsapigw.mbotsvc.dev.aws.binbash.com.ar
#
module "apigw_proxy" {
  for_each = toset(local.sites)

  source = "github.com/binbashar/terraform-aws-apigateway-v2.git?ref=v2.2.2"

  # General settings
  name          = "apigw-proxy-${each.value}"
  description   = "HTTP Proxy for ${each.value}"
  protocol_type = "HTTP"

  # E.g. site1.dev.diligentrobots.io
  domain_name                 = "${each.value}.${local.public_domain}"
  domain_name_certificate_arn = data.terraform_remote_state.certs.outputs.certificate_arn

  # Routing settings: create one route per app
  integrations = {
    for app in local.apps :
    "ANY /${local.url_apps_prefix}/${app}/{proxy+}" => {
      connection_type    = "VPC_LINK"
      connection_id      = aws_apigatewayv2_vpc_link.this[0].id
      integration_uri    = data.aws_lb_listener.nlb_https.arn
      integration_type   = "HTTP_PROXY"
      integration_method = "ANY"
      request_parameters = {
        # Get the part of the path captured in the {proxy+} variable and set it as the request path
        "overwrite:path" = "$request.path.proxy"
        # Pass the original client IP in a special header so it can be used later for IP filtering
        "overwrite:header.X-Client-Ip" = "$context.identity.sourceIp"
        "overwrite:header.X-Real-Ip"   = "$context.identity.sourceIp"
        # E.g. site1.dev.aws.diligentrobots.io
        # Important: host header only can be defined statically (can't use variables here)
        "overwrite:header.host" = "${join("", [each.value, "."])}${app}.${local.private_domain}"
      }
      tls_config = {
        server_name_to_verify = "${join("", [each.value, "."])}${app}.${local.private_domain}"
      }
    }
  }

  # Logging settings
  default_stage_access_log_destination_arn = aws_cloudwatch_log_group.this[each.value].arn
  default_stage_access_log_format          = local.log_format

  # Adjust throttling and bursting settings
  default_route_settings = {
    throttling_rate_limit  = 100
    throttling_burst_limit = 100
  }

  cors_configuration = {
    allow_headers     = ["*"]
    allow_methods     = ["*"]
    allow_origins     = ["*"]
    allow_credentials = "false"
    expose_headers    = ["*"]
    max_age           = 0
  }

  tags = local.tags
}

#
# Create a single VPC Link that will be shared by all API Gateways.
# Note that we had to do it this way due to the limitation on the number
# of VPC links per account per Region (currently 10).
#
resource "aws_apigatewayv2_vpc_link" "this" {
  count              = length(local.sites) > 0 ? 1 : 0
  name               = "apigw-proxy-default"
  security_group_ids = [aws_security_group.this[0].id]
  subnet_ids         = data.terraform_remote_state.eks-vpc.outputs.private_subnets
  tags               = local.tags
}

#
# Create a security group to control access through the VPC Link
#
resource "aws_security_group" "this" {
  count       = length(local.sites) > 0 ? 1 : 0
  name        = "apigw-proxy-vpc-link-default"
  description = "APIGW HTTP Proxy for default VPC Link"
  vpc_id      = data.terraform_remote_state.eks-vpc.outputs.vpc_id # "vpc-0ffb3f8d27ba934a4"
  tags        = local.tags

  ingress {
    description = "Allow all"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow EKS Private Subnets"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = data.terraform_remote_state.eks-vpc.outputs.private_subnets_cidr
  }
}

#
# Create a log group to store API Gateway logs
#
resource "aws_cloudwatch_log_group" "this" {
  for_each = toset(local.sites)

  name              = "${local.cloudwatch_group_prefix}${each.value}"
  retention_in_days = 7
  tags              = local.tags
}

#
# Create an alias record in Route 53 to connect every site's public domain to
# its corresponding custom domain on the API Gateway
#
resource "aws_route53_record" "this" {
  provider = aws.legacy

  for_each = toset(local.sites)

  # E.g. site1.dev.binbash.com.ar
  name    = "${each.value}.${local.public_domain}"
  type    = "A"
  zone_id = data.terraform_remote_state.legacy-dns.outputs.public_zone_id

  alias {
    name                   = module.apigw_proxy[each.value].apigatewayv2_domain_name_target_domain_name
    zone_id                = module.apigw_proxy[each.value].apigatewayv2_domain_name_hosted_zone_id
    evaluate_target_health = false
  }
}
