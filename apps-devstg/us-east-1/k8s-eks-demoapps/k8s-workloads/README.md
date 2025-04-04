# k8s-workloads reference layer

## Overview
This documentation should help you understand the different pieces that make up this
layer.
With such understanding you should be able to create copies of this
layer that are modified to having applications to test inside
of your kubernetes cluster.

Learn more about the components  [here](https://leverage.binbash.co/user-guide/ref-architecture-eks/components/).

Terraform code to deploy different applications in order to test the EKS cluster, the CI/CD pipelines,
and the resources already deployed in other layers.
Considering that we already have an [EKS Cluster](https://github.com/binbashar/le-tf-infra-aws/tree/master/apps-devstg/us-east-1/k8s-eks-demoapps)
deployed as baseline, with the `network`, `identities`, `cluster` and `k8s-components` layers, will allow us to
orchestrate deployments, applications, pipelines and define some applications in order to test the functionality
of the cluster and its resources.

## Code Organization
The EKS Workloads Layer (`apps-devstg/us-east-1/k8s-workloads`) is made up of different resources which
have clear, specific purposes.

### The "Emojivoto" application
In [this file](https://github.com/binbashar/le-tf-infra-aws/blob/master/apps-devstg/us-east-1/k8s-eks-demoapps/k8s-workloads/emojivoto.tf)
we define the kubernetes manifest for the application.
We pull the configuration from the [Kustomize templates](https://github.com/binbashar/le-demo-apps/tree/master/emojivoto/kustomize/overlays/devstg)
of the [Emojivoto Application](https://github.com/binbashar/le-emojivoto).
You can check some details in the [README.md](https://github.com/binbashar/le-emojivoto/blob/master/README.md) of the emojivoto application repository.

## Deployment
1. To deploy this layer, you only need to run `leverage tf init`, `leverage tf plan` and `leverage tf apply`
on the `apps-devstg/us-east-1/k8s-eks-demoapps/k8s-workloads` folder.
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