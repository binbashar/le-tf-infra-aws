#------------------------------------------------------------------------------
# FluentBit: capture pods logs and ship them to ElasticSearch/Kibana.
#------------------------------------------------------------------------------
resource "helm_release" "fluentbit" {
  count = var.logging.enabled ? 1 : 0

  name       = "fluentbit"
  namespace  = kubernetes_namespace.monitoring_logging[0].id
  repository = "https://fluent.github.io/helm-charts"
  chart      = "fluent-bit"
  version    = "0.53.0"
  values = [
    templatefile("chart-values/fluentbit.yaml", {
      opensearch_host         = "example-domain.${local.private_base_domain}", # Fetch this from a opensearch layer output
      opensearch_port         = 443,
      opensearch_index_suffix = local.environment
      region                  = var.region,
      role_arn                = data.terraform_remote_state.cluster-identities.outputs.fluent_bit_role_arn, # Make sure the role allows access to the domain set above
      tolerations             = local.tools_tolerations,
    })
  ]
}

#------------------------------------------------------------------------------
# k8s-event-logger: watch cluster events and output as logs for further processing.
#------------------------------------------------------------------------------
resource "helm_release" "k8s_event_logger" {
  count = var.logging.enabled && contains(var.logging.forwarders, "k8s-event-logger") ? 1 : 0

  name       = "k8s-event-logger"
  namespace  = kubernetes_namespace.monitoring_logging[0].id
  repository = "https://charts.deliveryhero.io/"
  chart      = "k8s-event-logger"
  version    = "1.1.8"
}

#------------------------------------------------------------------------------
# fluentd + AWS ElasticSearch: collect cluster logs and ship them to AWS ES
#------------------------------------------------------------------------------
resource "helm_release" "fluentd_awses" {
  count = var.logging.enabled && contains(var.logging.forwarders, "fluentd-awses") ? 1 : 0

  name       = "fluentd-awses"
  namespace  = kubernetes_namespace.monitoring_logging[0].id
  repository = "https://kokuwaio.github.io/helm-charts"
  chart      = "fluentd-elasticsearch"
  version    = "11.15.0"
  values = [
    templatefile("chart-values/fluentd-elasticsearch-aws.yaml", {
      roleArn = "arn:aws:iam::${var.accounts.shared.id}:role/aws-es-proxy"
    })
  ]
}

#------------------------------------------------------------------------------
# fluentd + Self-hosted ElasticSearch: collect cluster logs and ship them to ES
#------------------------------------------------------------------------------
resource "helm_release" "fluentd_selfhosted" {
  count = var.logging.enabled && contains(var.logging.forwarders, "fluentd-selfhosted") ? 1 : 0

  name       = "fluentd-selfhosted"
  namespace  = kubernetes_namespace.monitoring_logging[0].id
  repository = "https://kokuwaio.github.io/helm-charts"
  chart      = "fluentd-elasticsearch"
  version    = "11.15.0"
  values     = [file("chart-values/fluentd-elasticsearch-selfhosted.yaml")]
}
