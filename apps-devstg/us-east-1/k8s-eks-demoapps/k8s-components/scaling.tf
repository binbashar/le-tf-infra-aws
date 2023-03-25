#------------------------------------------------------------------------------
# Vertical Pod Autoscaler: automatic pod vertical autoscaling.
#------------------------------------------------------------------------------
resource "helm_release" "vpa" {
  count      = var.scaling.vpa ? 1 : 0
  name       = "vpa"
  namespace  = kubernetes_namespace.scaling[0].id
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
  count      = var.scaling.cluster_autoscaler ? 1 : 0
  name       = "autoscaler"
  namespace  = kubernetes_namespace.scaling[0].id
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
# Karpenter: a cluster autoscaler focused on cost efficiency via right-sizing.
#------------------------------------------------------------------------------
# This is a work in progress. It turns out that Karpenter's installation is
# quite involved: https://repost.aws/knowledge-center/eks-install-karpenter
#------------------------------------------------------------------------------
# resource "helm_release" "karpenter" {
#   count      = var.scaling.karpenter ? 1 : 0
#   name       = "karpenter"
#   namespace  = kubernetes_namespace.scaling[0].id
#   repository = "oci://public.ecr.aws/karpenter/karpenter"
#   chart      = "karpenter"
#   version    = "0.27.0"
#   values = [
#     <<-EOT
#     settings:
#       aws:
#         defaultInstanceProfile: KarpenterInstanceProfile
#         clusterEndpoint: "${CLUSTER_ENDPOINT}"
#         clusterName: ${CLUSTER_NAME}
#     serviceAccount:
#       annotations:
#         "eks\.amazonaws\.com/role-arn": "arn:aws:iam::${AWS_ACCOUNT_ID}:role/KarpenterControllerRole-${CLUSTER_NAME}"
#     EOT
#   ]
# }
