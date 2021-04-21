#------------------------------------------------------------------------------
# Linkerd EmojiVoto Demo Application
#------------------------------------------------------------------------------
# resource "helm_release" "emojivoto" {
#   name       = "emojivoto"
#   namespace  = kubernetes_namespace.argo_cd.id
#   repository = "https://binbashar.github.io/helm-charts/"
#   chart      = "argocd-application"
#   version    = "0.2.0"
#   values     = [ file("chart-values/demoapps-emojivoto.yaml") ]
#   depends_on = [ helm_release.argo_cd ]
# }

#------------------------------------------------------------------------------
# Google Microservices Demo
#------------------------------------------------------------------------------
# resource "helm_release" "gmd" {
#   name       = "gmd"
#   namespace  = kubernetes_namespace.argo_cd.id
#   repository = "https://binbashar.github.io/helm-charts/"
#   chart      = "argocd-application"
#   version    = "0.2.0"
#   values     = [ file("chart-values/demoapps-gmd.yaml") ]
#   depends_on = [ helm_release.argo_cd ]
# }

#------------------------------------------------------------------------------
# Weave Sock-Shop Microservices Demo
#------------------------------------------------------------------------------
# resource "helm_release" "sockshop" {
#   name       = "sockshop"
#   namespace  = kubernetes_namespace.argo_cd.id
#   repository = "https://binbashar.github.io/helm-charts/"
#   chart      = "argocd-application"
#   version    = "0.2.0"
#   values     = [ file("chart-values/demoapps-sockshop.yaml") ]
#   depends_on = [ helm_release.argo_cd ]
# }
