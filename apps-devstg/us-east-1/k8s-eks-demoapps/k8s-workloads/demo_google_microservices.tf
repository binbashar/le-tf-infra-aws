#------------------------------------------------------------------------------
# DemoApp: Google Microservices (DEV)
#------------------------------------------------------------------------------
resource "kubernetes_manifest" "google_microservices_dev" {
  field_manager {
    name            = "argo_applications"
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
        #
        # TODO Add the rest of the images
        #
        "argocd-image-updater.argoproj.io/image-list"                        = "763606934258.dkr.ecr.us-east-1.amazonaws.com/demo-google-microservices-adservice"
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
