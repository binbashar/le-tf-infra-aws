# k8s-workloads reference layer

## Overview
This documentation should help you understand the different pieces that make up this
layer.
With such understanding you should be able to create copies of this
layer, that will help having initial deployments of demo applications to test inside
of your kubernetes cluster, with the proper configuration to be able to handle all the lifecycle
with ArgoCD. More information and diagrams can be found down below.

Learn more about the components  [here](https://leverage.binbash.co/user-guide/ref-architecture-eks/components/).

Terraform code to deploy different applications in order to test the EKS cluster, the CI/CD pipelines,
and the resources already deployed in other layers.

## Pre-requisites
Considering that we already have an [EKS Cluster](https://github.com/binbashar/le-tf-infra-aws/tree/master/apps-devstg/us-east-1/k8s-eks-demoapps)
deployed as baseline, with the `network`, `identities`, `cluster` and `k8s-components` layers, will allow us to
orchestrate deployments, applications, pipelines and define some applications in order to test the functionality
of the cluster and its resources.

## What this layer deploys

Three workloads, in two different shapes. The shape matters more than the count:

| app | shape | hostname | needs |
| --- | --- | --- | --- |
| `echo-server` | native `kubernetes_*` resources, straight from Terraform | `echo-server.aws.binbash.com.ar` (private) **and** `echo-server.binbash.com.ar` (public) | the two Envoy gateways |
| `emojivoto` | **Argo CD `Application`** → kustomize overlay in [`le-demo-apps`](https://github.com/binbashar/le-demo-apps) | `emojivoto.aws.binbash.com.ar` (private) | `argocd.enabled` **and** `argocd.rollouts.enabled` in `k8s-components` |
| `google-microservices` | **Argo CD `Application`** → kustomize overlay in [`demo-google-microservices`](https://github.com/binbashar/demo-google-microservices) | `gmd.aws.binbash.com.ar` (private) | `argocd.enabled` + `external_secrets.enabled`, **and the `secrets` layer applied** |

Each app is one file, and each file owns everything that app needs — its
namespace, its `Application` (if it has one) and its `HTTPRoute`. The gateways
and route conventions those routes share live in `locals.tf`.

Toggle any of them with `demo_apps.<app>.enabled` in `terraform.tfvars`.

### Ordering

`kubernetes_manifest` validates against the live cluster at **plan** time, so
the two `Application` resources cannot be planned before `k8s-components` has
installed Argo CD. This layer therefore always runs last, and
`google-microservices` additionally wants the `secrets` layer applied first, or
its `paymentservice` never starts.

### The routes are owned here, the manifests are not

Both overlays still describe their exposure as nginx `Ingress` objects on the
`private-apps` class, which nothing has served since nginx-ingress was retired,
at hostnames the gateway's wildcard certificate cannot cover. Rather than route
through them, each `Application` deletes them with a kustomize `$patch: delete`
and this layer publishes an `HTTPRoute` instead — one label below the private
base domain, like every other route in the cluster. `emojivoto.tf` carries the
full reasoning, including the second patch it needs (a `vote-bot` env var the
upstream repo renders as an integer, which the API rejects).

### Smoke tests that mean something

A 200 on a home page proves the route, and nothing else. The two worth running:

```bash
# google-microservices: a completed checkout exercises paymentservice, which
# reads its secret via External Secrets from AWS Secrets Manager.
kubectl -n demo-google-microservices-dev get externalsecret backend-secrets
# ... then order something through https://gmd.aws.binbash.com.ar/

# emojivoto: a vote crosses web -> voting-svc over gRPC, and the blue/green
# promotion is only done when stable == current.
curl -s "https://emojivoto.aws.binbash.com.ar/api/vote?choice=:doughnut:"
kubectl argo rollouts get rollout web -n emojivoto
```

Both hostnames are private: VPN, or run the checks from a pod in the cluster.

### The "Emojivoto" application
In [this file](https://github.com/binbashar/le-tf-infra-aws/blob/master/apps-devstg/us-east-1/k8s-eks-demoapps/k8s-workloads/emojivoto.tf)
we define the kubernetes manifest for the application.
We pull the configuration from the [Kustomize templates](https://github.com/binbashar/le-demo-apps/tree/master/emojivoto/kustomize/overlays/devstg)
of the [Emojivoto Application](https://github.com/binbashar/le-emojivoto).
You can check some details in the [README.md](https://github.com/binbashar/le-emojivoto/blob/master/README.md) of the emojivoto application repository.

## Deployment
1. To deploy this layer, you only need to run `leverage tf init`, `leverage tf plan` and `leverage tf apply`
in this folder.
## Accessing the deployed applications (connectivity)
To access the Kubernetes resources using `kubectl` take into account that you need **connect
to the VPN** since all our implementations are via private endpoints (private VPC subnets).

## How the CI/CD workflow works?
[Diagram](https://github.com/binbashar/le-ref-architecture-doc/blob/master/docs/assets/images/diagrams/ci-cd-argocd-workflow.png)

1. A user commits (merges) changes to the [application code repo](https://github.com/binbashar/le-emojivoto).
2. The [image building workflow](https://github.com/binbashar/le-emojivoto/actions/workflows/build-images.yml) is triggered.
    * Image is built.
    * Image is pushed to ECR.
    * Throughout the process, the build process status is notified via Slack.
3. Argo Image Updater monitors ECR for new versions of the app image (it knows which image the app uses via a series of annotations in the Application object).
    * Argo Image Updater pushes a commit to the [Kustomize files repository](https://github.com/binbashar/le-demo-apps/blob/master/emojivoto/kustomize/overlays/devstg/kustomization.yml#L62) updating the definition for which image version the app should use.
4. Argo CD monitors the app kustomize definition files in the application manifests repository for changes.
    * If there are changes more recent than the ones currently applied in the cluster, Argo CD syncs those changes.
    * Throughout the syncing process the deployment status is notified via Slack.

Note you can use the [binbash Leverage kubectl command](https://leverage.binbash.co/user-guide/leverage-cli/reference/kubectl/) to access the cluster.