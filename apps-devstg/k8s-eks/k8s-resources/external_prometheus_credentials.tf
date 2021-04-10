# resource "kubernetes_cluster_role" "external_prometheus" {
#   metadata {
#     name      = "external-prometheus"
#   }

#   rule {
#     api_groups = [""]
#     resources  = [
#         "namespaces",
#         "nodes",
#         "nodes/proxy",
#         "services",
#         "services/proxy",
#         "endpoints",
#         "pods",
#         "pods/proxy",
#     ]
#     verbs = ["get", "list", "watch"]
#   }
# }

# resource "kubernetes_service_account" "external_prometheus" {
#   metadata {
#     name      = "external-prometheus"
#     namespace = kubernetes_namespace.monitoring.id
#   }
# }

# resource "kubernetes_cluster_role_binding" "external_prometheus" {
#   metadata {
#     name = "external-prometheus"
#   }
#   role_ref {
#     api_group = "rbac.authorization.k8s.io"
#     kind      = "ClusterRole"
#     name      = "external-prometheus"
#   }
#   subject {
#     kind      = "ServiceAccount"
#     name      = "external-prometheus"
#     namespace = kubernetes_namespace.monitoring.id
#   }
# }
