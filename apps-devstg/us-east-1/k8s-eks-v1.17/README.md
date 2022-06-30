# AWS EKS Reference Layer

## Overview
This documentation should help you understand the different pieces that make up this
EKS cluster. With such understanding you should be able to create your copies of this
cluster that are modified to serve other goals, such as having a cluster per environment.

Terraform code to orchestrate and deploy our EKS (cluster, network, k8s resources) reference
architecture. Consider that we already have an [AWS Landing Zone](https://github.com/binbashar/le-tf-infra-aws)
deployed as baseline which allow us to create, extend and enable new components on its grounds.

## Code Organization
The EKS layer (`apps-devstg/us-east-1/k8s-eks-v1.17`) is divided into sublayers which
have clear, specific purposes.

### The "network" layer
This is where we define the VPC resources for this cluster.

### The "cluster" layer
This is used to define the cluster attributes such as node groups and kubernetes version.

### The "identities" layer
This layer defines EKS IRSA roles that are later on assumed by roles running in the cluster.

### The "k8s-components" layer
This here defines the base cluster components such as ingress controllers, certificate managers, dns managers, ci/cd components, and more.

### The "k8s-workloads" layer
This here defines the cluster workloads such as web-apps, apis, back-end microservices, etc.

### Current EKS Cluster Creation Workflows

Following the [leverage terraform workflow](https://leverage.binbash.com.ar/user-guide/ref-architecture-aws/workflow/)
The EKS layers need to be orchestrated in the following order:

1. Network
    1. Edit the `network.auto.tfvars`
    2. Set the toggle to `true` to enable the creation of the NAT Gateway
    3. Then run `leverage tf apply`
2. Cluster
    1. Since we’re deploying a private K8s cluster you’ll need to be **connected to the VPN**
    2. Go to this layer and run `leverage tf apply`
    3. In the output you should see the credentials you need to talk to Kubernetes API via kubectl (or other clients).

```
apps-devstg//k8s-eks-v1.17/cluster$ leverage terraform output

...
kubectl_config = apiVersion: v1
preferences: {}
kind: Config

clusters:
- cluster:
    server: https://9E9E4EC03A0E83CF00A9A02F8EFC1F00.gr7.us-east-1.eks.amazonaws.com
    certificate-authority-data: LS0t...S0tLQo=
  name: eks_bb-apps-devstg-eks-demoapps

contexts:
- context:
    cluster: eks_bb-apps-devstg-eks-demoapps
    user: eks_bb-apps-devstg-eks-demoapps
  name: eks_bb-apps-devstg-eks-demoapps

current-context: eks_bb-apps-devstg-eks-demoapps

users:
- name: eks_bb-apps-devstg-eks-demoapps
  user:
    exec:
      apiVersion: client.authentication.k8s.io/v1alpha1
      command: aws-iam-authenticator
      args:
        - "token"
        - "-i"
        - "bb-apps-devstg-eks-demoapps"
        - --cache
      env:
        - name: AWS_CONFIG_FILE
          value: $HOME/.aws/bb/config
        - name: AWS_PROFILE
          value: bb-apps-devstg-devops
        - name: AWS_SHARED_CREDENTIALS_FILE
          value: $HOME/.aws/bb/credentials

```

3. Identities
    1. Go to this layer and run `leverage tf apply`

#### Setup auth and test cluster connectivity
1. Connecting to the K8s EKS cluster
2. Since we’re deploying a private K8s cluster you’ll need to be **connected to the VPN**
3. install `kubetcl` in your workstation
    1. https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/#install-using-native-package-management
    2. https://kubernetes.io/docs/tasks/tools/install-kubectl-macos/#install-with-homebrew-on-macos
    3. 📒 NOTE: consider using `kubectl` version 1.22 or 1.23 (not latest)
4. install `iam-authenticator` in your workstation
    1. https://docs.aws.amazon.com/eks/latest/userguide/install-aws-iam-authenticator.html
5. Export AWS credentials
   1. `export AWS_SHARED_CREDENTIALS_FILE="~/.aws/bb/credentials"`
   2. `export AWS_CONFIG_FILE="/.aws/bb/config"`
6. `k8s-eks-v1.17/cluster` layer should generate the `kubeconfig` file in the output of the apply, or by running `leverage tf output` similar to https://github.com/binbashar/le-devops-workflows/blob/master/README.md#eks-clusters-kubeconfig-file
    1. Edit that file to replace $HOME with the path to your home dir
    2. Place the kubeconfig in `~/.kube/bb/apps-devstg` and then use export `KUBECONFIG=~/.kube/bb/apps-devstg` to help tools like kubectl find a way to talk to the cluster (or `KUBECONFIG=~/.kube/bb/apps-devstg get pods --all-namespaces` )
    3. You should be now able to run kubectl  commands (https://kubernetes.io/docs/reference/kubectl/cheatsheet/)

### K8s EKS Cluster Components and Workloads deployment

1. Cluster Components (k8s-resources)
    1. Go to this layer and run `leverage tf apply`
    2. You can use the `apps.auto.tfvars` file to configure which components get installed
    3. Important: For private repo integrations after ArgoCD was successfully installed you will need to create this secret object in the cluster. Before creating the secret you need to update it to add the private SSH key that will grant ArgoCD permission to read the repository where the application definition files can be located. Note that this manual step is only a workaround that could be automated to simplify the orchestration.
2. Workloads (k8s-workloads)
    1. Go to this layer and run `leverage tf apply`

## Accessing the EKS Kubernetes resources (connectivity)
To access the Kubernetes resources using `kubectl` take into account that you need **connect
to the VPN** since all our implementations are via private endpoints (private VPC subnets).

### Connecting to ArgoCD
  1. Since we’re deploying a private K8s cluster you’ll need to be connected to the VPN
  2. From your web browser access to https://argocd.us-east-1.devstg.aws.binbash.com.ar/
  3. Considering the current `4.5.7` version we are using the default password it's stored in a secret.
    1. To obtain it, use this command: `kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d`  
  4. As Username, the default user is **admin**.
  5. You'll see the [EmojiVoto demo app](https://github.com/binbashar/le-demo-apps/tree/master/emojivoto/argocd) deployed and accessible at https://emojivoto.devstg.aws.binbash.com.ar/

**CONSIDERATION**
When running kubectl commands you could expect to get the following warning

`/apps-devstg/us-east-1/k8s-eks/cluster$ kubectl get pods -n argocd -l app.kubernetes.io/name=argocd-server -o name | cut -d'/' -f 2`

```
Cache file /home/user/.kube/cache/aws-iam-authenticator/credentials.yaml does not exist.
No cached credential available.  Refreshing...
Unable to cache credential: ProviderNotExpirer: provider SharedConfigCredentials: /home/user/.aws/bb/credentials does not support ExpiresAt()
```

about aws-iam-authenticator  `not finding an “expiresat” entry in this file /home/user/.aws/bb/credentials`

**UPDATE on the kubectl/aws-iam-authenticator warning:**

it seems to be related to this https://github.com/kubernetes-sigs/aws-iam-authenticator/issues/219
basically kubectl delegates on aws-iam-authenticator  to retrieve the token it needs to talk to the k8s API but aws-iam-auth  fails to provide that in the format that is expected by kubectl , given that is using an SSO flow it’s missing the ExpiresAt field.

In other words, using the old AWS IAM flow, aws-iam-auth  is able to comply because that flow does include an expiration value besides the temporary credentials; but the SSO flow doesn’t include the expiration value for the temporary credentials as such expiration exists at the SSO token level, not at temporary credentials level (which are obtained through said token)
