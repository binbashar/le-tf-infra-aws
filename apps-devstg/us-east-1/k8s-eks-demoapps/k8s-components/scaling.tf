#------------------------------------------------------------------------------
# Vertical Pod Autoscaler: automatic pod vertical autoscaling.
#------------------------------------------------------------------------------
resource "helm_release" "vpa" {
  count      = var.scaling.vpa.enabled ? 1 : 0
  name       = "vpa"
  namespace  = kubernetes_namespace.monitoring_metrics[0].id
  repository = "https://charts.fairwinds.com/stable"
  chart      = "vpa"
  version    = "4.12.5"
  values     = [file("chart-values/vpa.yaml")]
  depends_on = [helm_release.metrics_server]
}

#------------------------------------------------------------------------------
# Cluster Autoscaler: automatic cluster nodes autoscaling.
#------------------------------------------------------------------------------
resource "helm_release" "cluster_autoscaling" {
  count      = var.scaling.cluster_autoscaling.enabled ? 1 : 0
  name       = "autoscaler"
  namespace  = kubernetes_namespace.monitoring_metrics[0].id
  repository = "https://kubernetes.github.io/autoscaler"
  chart      = "cluster-autoscaler"
  version    = "9.55.1"
  values = [
    templatefile("chart-values/cluster-autoscaler.yaml",
      {
        awsRegion   = var.region
        clusterName = data.terraform_remote_state.cluster.outputs.cluster_name
        roleArn     = data.terraform_remote_state.cluster-identities.outputs.cluster_autoscaler_role_arn
      }
    )
  ]
}

#------------------------------------------------------------------------------
# Cluster Overprovisioning
#------------------------------------------------------------------------------
# This is useful when you have work loads that need to scale up quickly without
# waiting for the new cluster nodes to be created and join the cluster.
#------------------------------------------------------------------------------

# The cluster overprovisioner lets you create empty boxes:
#   - "replicaCount" controls how many of them
#   - Resources requests & limits controls how big they are
#
# Also keep in mind that these pods won't be doing anything really, so they
# will not use node resources; and they will be assigned the lowest priority,
# which will make them easy candidates for eviction.
# Another option is to start with one replica and then use the proportional
# autoscaler to control the minimum number of replicas there.
resource "helm_release" "cluster_overprovisioner" {
  count      = var.scaling.cluster_overprovisioning.enabled ? 1 : 0
  name       = "cluster-overprovisioner"
  namespace  = kubernetes_namespace.scaling[0].id
  repository = "https://charts.deliveryhero.io/"
  chart      = "cluster-overprovisioner"
  version    = "0.7.11"
  values = [
    <<EOF
    deployments:
      - name: default
        replicaCount: 2
        resources:
          limits:
            cpu: 1000m
            memory: 1000Mi
          requests:
            cpu: 1000m
            memory: 1000Mi
EOF
  ]
}

# This autoscaler can scale deployments (or replication controllers, or replica
# sets) based on the number of nodes or cores, and using a linear or ladder
# strategy.
#  - First decide which strategy best suits your use case, and then set the
#    cores or the nodes per replica to define how those values should define
#    the number of replicas of your target.
#  - Then, it is very important to factor in the instances on which the targets
#    managed by the proportional autoscaler will run. That's because these
#    targets must, as mush as possible, be assigned to a new node.
#  - Also, don't forget about using proper values for the min and max settings.
resource "helm_release" "cluster_proportional_autoscaler" {
  count      = var.scaling.cluster_overprovisioning.enabled ? 1 : 0
  name       = "cluster-proportional-autoscaler"
  namespace  = kubernetes_namespace.scaling[0].id
  repository = "https://kubernetes-sigs.github.io/cluster-proportional-autoscaler"
  chart      = "cluster-proportional-autoscaler"
  version    = "1.1.0"
  values = [
    <<EOF
    options:
      namespace: ${kubernetes_namespace.scaling[0].id}
      target: deployment/cluster-overprovisioner-default
    config:
      linear:
        coresPerReplica: 0
        nodesPerReplica: 1
        min: 2
        max: 25
        preventSinglePointFailure: true
        includeUnschedulableNodes: true
EOF
  ]
  depends_on = [helm_release.cluster_overprovisioner]
}



#------------------------------------------------------------------------------
# KEDA: autoscaling k8s pods
#------------------------------------------------------------------------------
#
# Kubernetes, a powerful container orchestration platform, revolutionized the way
# applications are deployed and managed. However, scaling applications to meet
# fluctuating workloads can be a complex task. KEDA, a Kubernetes-based
# Event-Driven Autoscaler, provides a simple yet effective solution to
# automatically scale Kubernetes Pods based on various metrics, including
# resource utilization, custom metrics, and external events.
#------------------------------------------------------------------------------
resource "helm_release" "keda" {
  count      = var.keda.enabled ? 1 : 0
  name       = "keda"
  namespace  = kubernetes_namespace.keda[0].id
  repository = "https://kedacore.github.io/charts"
  chart      = "keda"
  version    = "2.18.3"
  values     = []
}

resource "helm_release" "keda_http_add_on" {
  count      = var.keda.enabled && var.keda.http_add_on.enabled ? 1 : 0
  name       = "http-add-on"
  namespace  = kubernetes_namespace.keda[0].id
  repository = "https://kedacore.github.io/charts"
  chart      = "keda-add-ons-http"
  version    = "0.11.1"
  values     = []
}

# ------------------------------------------------------------------------------
# Goldilocks: tune up resource requests and limits.
#
# Hard dependency on VPA, not just an ordering preference: Goldilocks has no
# recommender of its own, it reads the VPA objects it creates per namespace.
# With `scaling.vpa.enabled = false` the dashboard installs and renders an
# empty table forever. Enabling goldilocks therefore means enabling VPA, which
# in turn pulls in metrics-server (see its count expression above).
# ------------------------------------------------------------------------------
resource "helm_release" "goldilocks" {
  count      = var.goldilocks.enabled ? 1 : 0
  name       = "goldilocks"
  namespace  = kubernetes_namespace.monitoring_metrics[0].id
  repository = "https://charts.fairwinds.com/stable"
  chart      = "goldilocks"
  version    = "10.5.0"
  values     = [file("chart-values/goldilocks.yaml")]
  depends_on = [helm_release.vpa]

  # The dependency above is an ordering hint; this is the contract. Without VPA
  # the chart installs happily and the dashboard renders an empty table
  # forever, which is indistinguishable from a broken route. Failing the plan
  # trades a silent wrong answer for a loud one.
  lifecycle {
    precondition {
      condition     = var.scaling.vpa.enabled
      error_message = "goldilocks requires scaling.vpa.enabled = true: it has no recommender of its own and reads the VPA objects it creates per namespace, so with VPA off the dashboard would render an empty table forever."
    }
  }
}

# ------------------------------------------------------------------------------
# Goldilocks dashboard exposure. See `local.private_gw_parent_refs` in locals.tf
# for the conventions every private route follows.
#
# The dashboard renders an empty table until a namespace carries the label
# `goldilocks.fairwinds.com/enabled=true` — that is what makes it create VPA
# objects. Reaching this hostname and finding nothing is the expected
# out-of-the-box state, not a broken route.
# ------------------------------------------------------------------------------
resource "kubernetes_manifest" "goldilocks_route_eg" {
  count = local.private_gw_enabled && var.goldilocks.enabled ? 1 : 0

  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "HTTPRoute"
    metadata = {
      name      = "goldilocks-dashboard"
      namespace = kubernetes_namespace.monitoring_metrics[0].id
    }
    spec = {
      parentRefs = local.private_gw_parent_refs
      hostnames  = ["goldilocks.${local.private_base_domain}"]
      rules = [{
        backendRefs = [{
          name = "goldilocks-dashboard"
          port = 80
        }]
      }]
    }
  }

  depends_on = [
    kubernetes_manifest.private_gateway_eg,
    helm_release.goldilocks,
  ]
}

moved {
  from = kubernetes_manifest.private_gw_routes["goldilocks"]
  to   = kubernetes_manifest.goldilocks_route_eg[0]
}
