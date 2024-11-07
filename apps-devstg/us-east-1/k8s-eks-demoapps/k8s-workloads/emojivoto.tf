locals {
  image_list = [
    "emojivoto-emoji-svc=763606934258.dkr.ecr.us-east-1.amazonaws.com/emojivoto-emoji-svc",
    "emojivoto-voting-svc=763606934258.dkr.ecr.us-east-1.amazonaws.com/emojivoto-voting-svc",
    "emojivoto-web=763606934258.dkr.ecr.us-east-1.amazonaws.com/emojivoto-web"
  ]
}
resource "kubernetes_manifest" "demo-emojivoto" {
  manifest = {
    "apiVersion" = "argoproj.io/v1alpha1"
    "kind"       = "Application"
    "metadata" = {
      "name"      = "demo-emojivoto"
      "namespace" = "argocd"
      "finalizers" = [
        "resources-finalizer.argocd.argoproj.io"
      ]
      "labels" = {
        "app" = "emojivoto"
        "env" = "devstg"
      }
      "annotations" = {
        "argocd-image-updater.argoproj.io/image-list"                        = join(",", local.image_list)
        "argocd-image-updater.argoproj.io/allow-tags"                        = "regexp:^[0-9]*-[a-z0-9]{7}$"
        "argocd-image-updater.argoproj.io/multibot-frontend.update-strategy" = "latest"
        "argocd-image-updater.argoproj.io/write-back-method"                 = "git"
        "argocd-image-updater.argoproj.io/write-back-target"                 = "kustomization"
      }
    }

    "spec" = {
      "destination" = {
        "server"    = "https://kubernetes.default.svc"
        "namespace" = "emojivoto"
      }
      "project" = "default"
      "source" = {
        "repoURL"        = "git@github.com:binbashar/le-demo-apps.git"
        "targetRevision" = "feat/add-emojivoto-kustomize-definitions"
        "path"           = "emojivoto/kustomize/overlays/devstg"
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
