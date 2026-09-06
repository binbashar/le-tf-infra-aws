#------------------------------------------------------------------------------
# DemoApp: Google Microservices / Online Boutique (DEV)
# (https://github.com/binbashar/demo-google-microservices)
#
# The larger of the two GitOps workloads: twelve services behind one web
# frontend, delivered by Argo CD from the kustomize overlay in a **private**
# repository — Argo CD reads it with the deploy key `cicd-argo.tf` pulls from
# Secrets Manager in the shared account. Same platform requirements as
# emojivoto, minus Rollouts: everything here is a plain Deployment.
#
# It is also the only workload on this cluster that exercises **External
# Secrets**. Its base ships an `ExternalSecret` reading
# `/k8s-eks-demoapps/test-secrets` through the `cluster-secrets-manager`
# ClusterSecretStore, and `paymentservice` consumes the resulting `app-secrets`
# Secret with a `secretKeyRef` carrying no `optional: true`. So the chain
# Secrets Manager -> IRSA -> ESO -> pod is load-bearing, not decorative: break
# any link and `paymentservice` sits in `CreateContainerConfigError` while
# `checkoutservice` fails every order. That is what makes completing a checkout
# the real test of this app. Requires `external_secrets.enabled` in
# `k8s-components` and the `secrets` layer applied.
#
# `loadgenerator` (10 simulated users) is left running: it is the only source of
# sustained traffic on this cluster, which is what makes the cluster-autoscaler
# and any metrics worth looking at. It also means this app never idles cheaply.
#
# Routing: one hostname, private only.
#
#   - gmd.aws.binbash.com.ar → Envoy Gateway, private-gw-eg. VPN only.
#
# Smoke-testing (VPN required):
#
#   curl -sSf https://gmd.aws.binbash.com.ar/ | head
#   # The checkout path is the one that proves the secret chain:
#   kubectl -n demo-google-microservices-dev get externalsecret backend-secrets
#   kubectl -n demo-google-microservices-dev get secret app-secrets
#
# The overlay's `frontend-private` Ingress is deleted here for the same reason
# emojivoto's three are — dead `private-apps` class, a hostname the gateway's
# wildcard cannot cover, and a `cert-manager.io/cluster-issuer` annotation that
# would issue a real certificate for it anyway. See the longer note in
# `emojivoto.tf`.
#------------------------------------------------------------------------------

locals {
  gmd_namespace = "demo-google-microservices-dev"
  gmd_host      = "gmd.aws.binbash.com.ar"

  # The Secrets Manager entry this app's `ExternalSecret` reads, owned by the
  # `secrets` layer. Named here so the guard below and the error message stay in
  # step with each other.
  gmd_secret_name = "/k8s-eks-demoapps/test-secrets"

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

#------------------------------------------------------------------------------
# Fails the plan if the `secrets` layer has not been applied.
#
# Without this the omission is invisible until well after the apply succeeds:
# Argo CD syncs, ESO cannot read the source, `backend-secrets` goes to
# `SecretSyncedError`, `app-secrets` is never created, and `paymentservice` sits
# in `CreateContainerConfigError` while every checkout fails. Three hops from
# the cause, in a different layer, minutes later.
#
# The `secrets` layer is destroyed and re-applied with the rest of the stack
# rather than left standing between runs, so "it was there last time" is not
# evidence — which is exactly why this guard exists.
#
# Uses the *plural* data source deliberately: `aws_secretsmanager_secret`
# (singular) raises its own error when the secret is missing, naming the data
# source and nothing else. The plural one returns an empty set instead, which
# lets the precondition below say what is wrong and which layer fixes it. The
# `name` filter is a prefix match, hence the exact `contains` check.
#------------------------------------------------------------------------------
data "aws_secretsmanager_secrets" "gmd_backend" {
  count = var.demo_apps.google_microservices_dev.enabled ? 1 : 0

  filter {
    name   = "name"
    values = [local.gmd_secret_name]
  }
}

# Owned here rather than left to `CreateNamespace=true`, so the HTTPRoute below
# has a namespace to be created in during this same apply. See the equivalent
# note in emojivoto.tf.
resource "kubernetes_namespace" "google_microservices_dev" {
  count = var.demo_apps.google_microservices_dev.enabled ? 1 : 0

  metadata {
    name = local.gmd_namespace
  }
}

resource "kubernetes_manifest" "google_microservices_dev" {
  count = var.demo_apps.google_microservices_dev.enabled ? 1 : 0

  # Argo CD writes to its own Application objects — status, and the operation
  # bookkeeping it stamps into labels and annotations. Without these the next
  # plan reports drift on every sync.
  computed_fields = [
    "metadata.labels",
    "metadata.annotations",
    "metadata.finalizers",
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
      # Read only by argocd-image-updater, which is not installed. Kept because
      # they are the app's declaration of how it wants to be updated, and the
      # updater is a flag away in k8s-components.
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
        "namespace" = local.gmd_namespace
      }
      "project" = "default"
      "source" = {
        "repoURL"        = "git@github.com:binbashar/demo-google-microservices.git"
        "targetRevision" = "master"
        "path"           = "kustomize/overlays/dev"

        "kustomize" = {
          "patches" = [
            {
              "target" = {
                "kind" = "Ingress"
                "name" = "frontend-private"
              }
              "patch" = <<-YAML
                $patch: delete
                apiVersion: networking.k8s.io/v1
                kind: Ingress
                metadata:
                  name: frontend-private
              YAML
            }
          ]
        }
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

  lifecycle {
    precondition {
      condition     = contains(data.aws_secretsmanager_secrets.gmd_backend[0].names, local.gmd_secret_name)
      error_message = "${local.gmd_secret_name} does not exist in this account, so this app's ExternalSecret cannot resolve and paymentservice will never start. Apply the `secrets` layer first (it is the sixth of the seven, between k8s-components and this one), or set demo_apps.google_microservices_dev.enabled = false."
    }
  }

  depends_on = [
    kubernetes_namespace.google_microservices_dev,
  ]
}

#------------------------------------------------------------------------------
# Envoy Gateway, private path. Created before Argo CD syncs the `frontend`
# Service, so it resolves to nothing for the first minutes and Envoy answers
# 503; it repairs itself once the backend appears.
#------------------------------------------------------------------------------
resource "kubernetes_manifest" "google_microservices_dev_route_eg" {
  count = var.demo_apps.google_microservices_dev.enabled ? 1 : 0

  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "HTTPRoute"
    metadata = {
      name      = "google-microservices-dev-eg"
      namespace = kubernetes_namespace.google_microservices_dev[0].metadata[0].name
    }
    spec = {
      parentRefs = local.private_gw_parent_refs
      hostnames  = [local.gmd_host]
      rules = [{
        backendRefs = [{
          name = "frontend"
          port = 80
        }]
      }]
    }
  }
}

moved {
  from = kubernetes_manifest.google_microservices_dev
  to   = kubernetes_manifest.google_microservices_dev[0]
}

#------------------------------------------------------------------------------
# DemoApp: Google Microservices (PRD)
#------------------------------------------------------------------------------
#
# TODO Add the production version once we get the dev one working
#
