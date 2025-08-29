#------------------------------------------------------------------------------
# DemoApp: Google Microservices (DEV)
#------------------------------------------------------------------------------
locals {
  gmd_image_list = [
    "emailservice=763606934258.dkr.ecr.us-east-1.amazonaws.com/demo-google-microservices-emailservice",
    "productcatalogservice=763606934258.dkr.ecr.us-east-1.amazonaws.com/demo-google-microservices-productcatalogservice",
    "recommendationservice=763606934258.dkr.ecr.us-east-1.amazonaws.com/demo-google-microservices-recommendationservice",
    "shippingservice=763606934258.dkr.ecr.us-east-1.amazonaws.com/demo-google-microservices-shippingservice",
    "checkoutservice=763606934258.dkr.ecr.us-east-1.amazonaws.com/demo-google-microservices-checkoutservice",
    "paymentservice=763606934258.dkr.ecr.us-east-1.amazonaws.com/demo-google-microservices-paymentservice",
    "currencyservice=763606934258.dkr.ecr.us-east-1.amazonaws.com/demo-google-microservices-currencyservice",
    "cartservice=763606934258.dkr.ecr.us-east-1.amazonaws.com/demo-google-microservices-cartservice",
    "frontend=763606934258.dkr.ecr.us-east-1.amazonaws.com/demo-google-microservices-frontend",
    "adservice=763606934258.dkr.ecr.us-east-1.amazonaws.com/demo-google-microservices-adservice",
  ]
}
resource "kubernetes_manifest" "google_microservices_dev" {
  computed_fields = [
    "metadata.labels",
    "metadata.annotations",
    "metadata.finalizers",
    "spec.source.helm.version",
  ]
  field_manager {
    name = "argo_applications"
    # force field manager conflicts to be overridden
    force_conflicts = true
  }
  manifest = {
    "apiVersion" = "argoproj.io/v1alpha1"
    "kind"       = "Application"
    "metadata" = {
      "name"      = "google-microservices-dev"
      "namespace" = "argocd"
      "finalizers" = [
        "resources-finalizer.argocd.argoproj.io"
      ]
      "labels" = {
        "app" = "google-microservices"
        "env" = "dev"
      }
      "annotations" = {
        "argocd-image-updater.argoproj.io/image-list"                        = join(",", local.gmd_image_list)
        "argocd-image-updater.argoproj.io/multibot-frontend.update-strategy" = "latest"
        "argocd-image-updater.argoproj.io/write-back-method"                 = "git"
        "argocd-image-updater.argoproj.io/write-back-target"                 = "kustomization"
      }
    }

    "spec" = {
      "destination" = {
        "server"    = "https://kubernetes.default.svc"
        "namespace" = "demo-google-microservices-dev"
      }
      "project" = "default"
      "source" = {
        "repoURL"        = "git@github.com:binbashar/demo-google-microservices.git"
        "targetRevision" = "master"
        "path"           = "kustomize/overlays/dev"

        # "kustomize" = {
        #   "namePrefix"   = "dev-"
        #   "commonLabels" = {
        #     "environment" = "dev"
        #   }
        # }
      }
      "syncPolicy" = {
        "automated" = {
          "prune"    = true
          "selfHeal" = true
        }
        "syncOptions" = [
          "CreateNamespace=true",
          "Prune=true",
          "ServerSideApply=true",
        ]
      }
    }
  }
}


#------------------------------------------------------------------------------
# DemoApp: Google Microservices (PRD)
#------------------------------------------------------------------------------
#
# TODO Add the production version once we get the dev one working
#
