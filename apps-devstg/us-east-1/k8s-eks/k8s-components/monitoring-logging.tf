#------------------------------------------------------------------------------
# FluentBit: capture pods logs and ship them to ElasticSearch/Kibana.
#------------------------------------------------------------------------------
resource "helm_release" "fluentbit" {
  count = var.logging.enabled ? 1 : 0

  name       = "fluentbit"
  namespace  = kubernetes_namespace.monitoring_logging[0].id
  repository = "https://fluent.github.io/helm-charts"
  chart      = "fluent-bit"
  version    = "0.20.1"
  values = [
    templatefile("chart-values/fluentbit.yaml", {
      es_host     = "elasticsearch.${local.private_base_domain}",
      es_port     = 443,
      es_user     = "elastic.user",    # TODO pass secret via AWS Screts Manager
      es_password = "elastic.password" # TODO pass secret via AWS Screts Manager
    })
    # templatefile("chart-values/fluentbit.yaml", {
    #   opensearch_host = "opensearch.endpoint",
    #   opensearch_port = 443,
    #   region          = var.region,
    #   role_arn        = data.terraform_remote_state.eks-identities.outputs.fluent_bit_role_arn,
    #   tolerations     = jsonencode([
    #     {
    #       key      = "stack",
    #       operator = "Equal",
    #       value    = "monitoring",
    #       effect   = "NoSchedule"
    #     },
    #     {
    #       key      = "stack",
    #       operator = "Equal",
    #       value    = "argocd",
    #       effect   = "NoSchedule"
    #     }
    #   ]),
    #   opensearch_index_suffix = local.environment
    # })
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
  version    = "1.0.0"
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
  version    = "11.12.0"
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
  version    = "11.12.0"
  values     = [file("chart-values/fluentd-elasticsearch-selfhosted.yaml")]
}
