#------------------------------------------------------------------------------
# DemoApp: emojivoto (https://github.com/binbashar/le-emojivoto)
#
# Unlike echo-server, which this layer deploys as native `kubernetes_*`
# resources, emojivoto is delivered by **Argo CD**: the resource below is an
# `Application` pointing at the kustomize overlay in `binbashar/le-demo-apps`,
# and Argo CD is what actually creates the workloads. That is the whole point of
# this app being here — it is the layer's GitOps path under test, not just a
# second workload. It needs, in `k8s-components`:
#
#   - `argocd.enabled`          — the Application CRD this manifest validates
#                                 against at *plan* time, so k8s-components has
#                                 to be applied before this layer plans at all.
#   - `argocd.rollouts.enabled` — the app's workloads are `kind: Rollout`
#                                 (blue/green), not Deployments. Argo CD would
#                                 sync to a resource type the API server does
#                                 not know without it. The two argocd flags are
#                                 evaluated independently, so both must move.
#
# Images come from ECR in the shared account; the repository policy grants pull
# to apps-devstg, so the nodes need no extra credential.
#
# Routing: one hostname, private only.
#
#   - emojivoto.aws.binbash.com.ar → Envoy Gateway, private-gw-eg. VPN only.
#
# `emoji-svc` and `voting-svc` get no route: they speak gRPC and are consumed
# in-cluster by `web` alone. The overlay used to publish them anyway, which was
# never useful.
#
# Smoke-testing (VPN required):
#
#   curl -sSf https://emojivoto.aws.binbash.com.ar/ | head
#   # `vote-bot` votes continuously, so the leaderboard fills on its own:
#   curl -s https://emojivoto.aws.binbash.com.ar/api/list | head -c 300
#
#   # Blue/green state, via the Argo Rollouts plugin:
#   kubectl argo rollouts get rollout web -n emojivoto
#
#------------------------------------------------------------------------------
# Two defects in the upstream overlay are corrected here rather than there, with
# `spec.source.kustomize.patches` — Argo CD appends these to the overlay's own
# kustomization, so they run after its patches. Both fixes belong upstream
# eventually; see the follow-up in PLATFORM-NOTES.md.
#
#   1. **The three Ingresses are deleted.** They carry
#      `kubernetes.io/ingress.class: private-apps`, a class nothing has served
#      since nginx-ingress was retired, at hostnames three labels below the
#      private base domain that the gateway's wildcard cannot cover. Left in
#      place they would not route — but they would not be inert either: the
#      `cert-manager.io/cluster-issuer` annotation on each one makes
#      cert-manager's ingress-shim request an ACME certificate per host, real
#      issuances against the rate limit for hostnames nothing can reach.
#
#   2. **`vote-bot`'s `TTL` becomes a string.** The overlay renders
#      `value: 600` — a YAML integer where the API demands a string, which the
#      API server rejects outright. Confirmed by rendering the overlay with
#      `kubectl kustomize`, so this is not a version-drift guess: the app cannot
#      ever have synced with that Deployment in it.
#
# `$patch: delete` is kustomize's own idiom for removing a resource a base
# contributes; it is the only form that works from here, since `patches` can
# rewrite fields but not shorten the `resources` list.
#------------------------------------------------------------------------------

locals {
  emojivoto_namespace = "emojivoto"
  emojivoto_host      = "emojivoto.aws.binbash.com.ar"

  emojivoto_image_list = [
    "emojivoto-emoji-svc=763606934258.dkr.ecr.us-east-1.amazonaws.com/emojivoto-emoji-svc",
    "emojivoto-voting-svc=763606934258.dkr.ecr.us-east-1.amazonaws.com/emojivoto-voting-svc",
    "emojivoto-web=763606934258.dkr.ecr.us-east-1.amazonaws.com/emojivoto-web"
  ]

  # Deleting a resource a base contributes, in kustomize's strategic-merge
  # dialect. Only `kind`/`name` identify the target, so one helper covers all
  # three Ingresses.
  emojivoto_dead_ingresses = ["web-svc-ingress", "emoji-svc-ingress", "voting-svc-ingress"]
}

#------------------------------------------------------------------------------
# The namespace is owned here, not left to the Application's
# `CreateNamespace=true`, for the same reason echo-server's is: the HTTPRoute
# below is created by Terraform and needs the namespace to exist within this
# same apply, before Argo CD has synced anything. `CreateNamespace=true` stays
# on and simply finds it already there.
#------------------------------------------------------------------------------
resource "kubernetes_namespace" "emojivoto" {
  count = var.demo_apps.emojivoto.enabled ? 1 : 0

  metadata {
    name = local.emojivoto_namespace
  }
}

resource "kubernetes_manifest" "demo-emojivoto" {
  count = var.demo_apps.emojivoto.enabled ? 1 : 0

  # Argo CD writes to its own Application objects — status, and the operation
  # bookkeeping it stamps into labels and annotations. Without these the next
  # plan reports drift on every sync.
  computed_fields = [
    "metadata.labels",
    "metadata.annotations",
    "metadata.finalizers",
  ]
  field_manager {
    name            = "argo_applications"
    force_conflicts = true
  }

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
      # Read only by argocd-image-updater, which is not installed. Kept because
      # they are the app's declaration of how it wants to be updated, and the
      # updater is a flag away in k8s-components.
      "annotations" = {
        "argocd-image-updater.argoproj.io/image-list"                           = join(",", local.emojivoto_image_list)
        "argocd-image-updater.argoproj.io/allow-tags"                           = "regexp:^[0-9]*-[a-z0-9]{7}$"
        "argocd-image-updater.argoproj.io/emojivoto-emoji-svc.update-strategy"  = "latest"
        "argocd-image-updater.argoproj.io/emojivoto-voting-svc.update-strategy" = "latest"
        "argocd-image-updater.argoproj.io/emojivoto-web.update-strategy"        = "latest"
        "argocd-image-updater.argoproj.io/write-back-method"                    = "git"
        "argocd-image-updater.argoproj.io/write-back-target"                    = "kustomization"
      }
    }

    "spec" = {
      "destination" = {
        "server"    = "https://kubernetes.default.svc"
        "namespace" = local.emojivoto_namespace
      }
      "project" = "default"
      "source" = {
        # HTTPS and anonymous, unlike the private google-microservices repo
        # next door, because `le-demo-apps` is a **public** repository — it is
        # published as Leverage reference material. It used to be read over SSH
        # with a deploy key from Secrets Manager, and that stopped working
        # silently: the repository was made public in April 2025 and its deploy
        # key was deleted from GitHub with it (`gh api repos/.../keys` returns
        # an empty list), while the now-orphaned key stayed in Secrets Manager
        # and stayed wired into the Argo CD chart. The failure surfaces only at
        # sync time, as `ComparisonError: ssh: handshake failed … no supported
        # methods remain` on an Application whose health still reads `Healthy`
        # because nothing was ever deployed to be unhealthy.
        #
        # A public repo needs no credential at all, so this drops one rather
        # than reissuing it. The deploy-key path is still exercised — by
        # `demo_google_microservices.tf`, whose repository really is private.
        "repoURL"        = "https://github.com/binbashar/le-demo-apps.git"
        "targetRevision" = "HEAD"
        "path"           = "emojivoto/kustomize/overlays/devstg"

        "kustomize" = {
          "patches" = concat(
            [
              for name in local.emojivoto_dead_ingresses : {
                "target" = {
                  "kind" = "Ingress"
                  "name" = name
                }
                "patch" = <<-YAML
                  $patch: delete
                  apiVersion: networking.k8s.io/v1
                  kind: Ingress
                  metadata:
                    name: ${name}
                YAML
              }
            ],
            [
              {
                "target" = {
                  "kind" = "Deployment"
                  "name" = "vote-bot"
                }
                # Strategic merge, so the env list merges on `name` rather than
                # being replaced wholesale or addressed by index.
                "patch" = <<-YAML
                  apiVersion: apps/v1
                  kind: Deployment
                  metadata:
                    name: vote-bot
                  spec:
                    template:
                      spec:
                        containers:
                          - name: vote-bot
                            env:
                              - name: TTL
                                value: "600"
                YAML
              }
            ]
          )
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

  depends_on = [
    kubernetes_namespace.emojivoto,
  ]
}

#------------------------------------------------------------------------------
# Envoy Gateway, private path. `web-svc` is the *active* Service of the
# blue/green Rollout, so this always points at the promoted revision;
# `web-svc-preview` is deliberately not published.
#
# The route is created before Argo CD has synced the backend, so it resolves to
# nothing for the first minute or two and Envoy answers 503. It repairs itself
# the moment the Service appears — no ordering dependency to encode.
#------------------------------------------------------------------------------
resource "kubernetes_manifest" "emojivoto_route_eg" {
  count = var.demo_apps.emojivoto.enabled ? 1 : 0

  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "HTTPRoute"
    metadata = {
      name      = "emojivoto-eg"
      namespace = kubernetes_namespace.emojivoto[0].metadata[0].name
    }
    spec = {
      parentRefs = local.private_gw_parent_refs
      hostnames  = [local.emojivoto_host]
      rules = [{
        backendRefs = [{
          name = "web-svc"
          port = 80
        }]
      }]
    }
  }
}

moved {
  from = kubernetes_manifest.demo-emojivoto
  to   = kubernetes_manifest.demo-emojivoto[0]
}
