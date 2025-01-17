#------------------------------------------------------------------------------
# Vertical Pod Autoscaler: automatic pod vertical autoscaling.
#------------------------------------------------------------------------------
resource "helm_release" "vpa" {
  count      = var.scaling.vpa.enabled ? 1 : 0
  name       = "vpa"
  namespace  = kubernetes_namespace.monitoring_metrics[0].id
  repository = "https://charts.fairwinds.com/stable"
  chart      = "vpa"
  version    = "0.3.2"
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
  version    = "9.18.1"
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
  count      = var.enable_keda ? 1 : 0
  name       = "keda"
  namespace  = kubernetes_namespace.keda[0].id
  repository = "https://kedacore.github.io/charts"
  chart      = "keda"
  version    = "2.15.0"
  values = []
}

resource "helm_release" "keda_http_add_on" {
  count      = var.enable_keda && var.enable_keda_http_add_on ? 1 : 0
  name       = "http-add-on"
  namespace  = kubernetes_namespace.keda[0].id
  repository = "https://kedacore.github.io/charts"
  chart      = "keda-add-ons-http"
  version    = "0.8.0"
  values     = []
}

# ------------------------------------------------------------------------------
# Goldilocks: tune up resource requests and limits.
# ------------------------------------------------------------------------------
resource "helm_release" "goldilocks" {
  count      = var.goldilocks.enabled ? 1 : 0
  name       = "goldilocks"
  namespace  = kubernetes_namespace.monitoring_metrics[0].id
  repository = "https://charts.fairwinds.com/stable"
  chart      = "goldilocks"
  version    = "3.2.1"
  values = [
    templatefile("chart-values/goldilocks.yaml", {
      goldilocksHost = "goldilocks.${local.platform}.${local.private_base_domain}"
    })
  ]
  depends_on = [helm_release.vpa]
}
