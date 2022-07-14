# AWS EKS Reference Layer

## Overview
This documentation should help you understand the different pieces that make up this
EKS cluster. With such understanding you should be able to create your copies of this
cluster that are modified to serve other goals, such as having a cluster per environment.

Terraform code to orchestrate and deploy our EKS (cluster, network, k8s resources) reference
architecture. Consider that we already have an [AWS Landing Zone](https://github.com/binbashar/le-tf-infra-aws)
deployed as baseline which allow us to create, extend and enable new components on its grounds.

## Code Organization
The EKS layer (`apps-devstg/us-east-1/k8s-eks`) is divided into sub-layers which
have clear, specific purposes.

### The "network" layer
This is where we define the VPC resources for this cluster.

### The "cluster" layer
This is used to define the cluster attributes such as node groups and kubernetes version.

### The "identities" layer
This layer defines EKS IRSA roles that are later on assumed by roles running in the cluster.

### The "k8s-components" layer
This here defines the base cluster components such as ingress controllers,
certificate managers, dns managers, ci/cd components, and more.

### The "k8s-workloads" layer
This here defines the cluster workloads such as web-apps, apis, back-end microservices, etc.

## Important: read this if you are copying the EKS layer to stand up a new cluster
The typical use cases would be:
- You need to set up a new cluster in a new account
- Or you need to set up another cluster in an existing account which already has a cluster

Below we'll cover the first case but we'll assume that we are creating the `prd` cluster from the code that
defines the `devstg` cluster:
1. First, you would copy-paste an existing EKS layer along with all its sub-layers: `cp -r apps-devstg/us-east-1/k8s-eks apps-prd/us-east-1/k8s-eks`
2. Then, you need to go through each layer, open up the `config.tf` file and replace any occurrences of `devstg` with `prd`.
   1. There should be a `config.tf` in each sublayer so please make sure you cover all of them.

Now that you created the layers for the cluster you need to create a few other layers in the
new account that the cluster layers depend on, they are:

3. The `security-keys` layer
    - This layer creates a KMS key that we use for encrypting EKS state.
    - The procedure to create this layer is similar to the previous steps.
      - You need to copy the layer from the `devstg` account and adjust its files to replace occurrences of `devstg` with `prd`.
    - Finally you need to run the Terraform Workflow (init and apply).
4. The `security-certs` layer
    - This layer creates the AWS Certificate Manager certificates that are used by the AWS ALBs that are created by the ALB Ingress Controller.
    - A similar procedure to create this layer. Get this layer from `devstg`, replace references to `devstg` with `prd`, and then run init & apply.

### Current EKS Cluster Creation Workflows

Following the [leverage terraform workflow](https://leverage.binbash.com.ar/user-guide/ref-architecture-aws/workflow/)
The EKS layers need to be orchestrated in the following order:

1. Network
    1. Open the `locals.tf` file and make sure the VPC CIDR and subnets are correct.
       1. Check the CIDR/subnets definition that were made for DevStg and Prd clusters and avoid segments overlapping.
    2. In the same `locals.tf` file, there is a "VPC Peerings" section.
       1. Make sure it contains the right entries to match the VPC peerings that you actually need to set up.
    3. In the `variables.tf` file you will find several variables you can use to configure multiple settings.
       1. For instance, if you anticipate this cluster is going to be permanent, you could set the `vpc_enable_nat_gateway` flag to `true`;
       2. or if you are standing up a production cluster, you may want to set `vpc_single_nat_gateway` to `false` in order to have a NAT Gateways per availability zone.
2. Cluster
    1. Since we’re deploying a private K8s cluster you’ll need to be **connected to the VPN**
    2. Check out the `variables.tf` file to configure the Kubernetes version or whether you want to create a cluster with a public endpoint (in most cases you don't but the possibility is there).
    3. Open up `locals.tf` and make sure the `map_accounts`, `map_users` and `map_roles` variables define the right accounts, users and roles that will be granted permissions on the cluster.
    4. Then open `eks-managed-nodes.tf` to set the node groups and their attributes according to your requirements.
       1. In this file you can also configure security group rules, both for granting access to the cluster API or to the nodes.
    5. Go to this layer and run `leverage tf apply`
    6. In the output you should see the credentials you need to talk to Kubernetes API via kubectl (or other clients).

#### Setup auth and test cluster connectivity
1. Connecting to the K8s EKS cluster
2. Since we’re deploying a private K8s cluster you’ll need to be **connected to the VPN**
3. install `kubetcl` in your workstation
    1. https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/#install-using-native-package-management
    2. https://kubernetes.io/docs/tasks/tools/install-kubectl-macos/#install-with-homebrew-on-macos
    3. 📒 NOTE: consider using `kubectl` version 1.22-1.24 (depending on your cluster version)
4. If working with AWS SSO approach refresh your temporary credentials
   1. `leverage terraform init`
5. Export AWS credentials
   1. `export AWS_SHARED_CREDENTIALS_FILE="~/.aws/bb/credentials"`
   2. `export AWS_CONFIG_FILE="~/.aws/bb/config"`
6. To generate `k8s-eks/cluster` layer `kubeconfig` file
   1. `export KUBECONFIG=~/.kube/bb/config-bb-devstg-k8s-eks`
   2. `aws eks update-kubeconfig --region us-east-1 --name bb-apps-devstg-eks-1ry --profile bb-apps-devstg-devops`
   3. Edit `~/.kube/bb/apps-devstg/config-bb-devstg-k8s-eks` and add the proper env vars to let kubeconfig notice the AWS creds path
   ```
   env:
      - name: AWS_PROFILE
        value: bb-apps-devstg-devops
      - name: AWS_CONFIG_FILE
        value: /Users/exequielbarrirero/.aws/bb/config
      - name: AWS_SHARED_CREDENTIALS_FILE
        value: /Users/exequielbarrirero/.aws/bb/credentials
   ```
   4. Place the kubeconfig in `~/.kube/bb/apps-devstg` and then use export `KUBECONFIG=~/.kube/bb/apps-devstg` to help tools like kubectl find a way to talk to the cluster (or `KUBECONFIG=~/.kube/bb/apps-devstg get pods --all-namespaces` )
   5. You should be now able to run kubectl  commands (https://kubernetes.io/docs/reference/kubectl/cheatsheet/)

#### Example kubeconfig
```
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: LS0tLS1CRUdJTiBDRVJUSUZJQXXXXXXXXXXXXXXXXXXXXXXXXXXXUFBNPQotLS0tLUVORCBDRVJUSUZJQ0FURS0tLS0tCg==
    server: https://16DXXXXXXXXXXXXXXXXXXXX1C33.gr7.us-east-1.eks.amazonaws.com
  name: arn:aws:eks:us-east-1:XXXXXXXXXXXX:cluster/bb-apps-devstg-eks-1ry
contexts:
- context:
    cluster: arn:aws:eks:us-east-1:XXXXXXXXXXXX:cluster/bb-apps-devstg-eks-1ry
    user: arn:aws:eks:us-east-1:XXXXXXXXXXXX:cluster/bb-apps-devstg-eks-1ry
  name: arn:aws:eks:us-east-1:XXXXXXXXXXXX:cluster/bb-apps-devstg-eks-1ry
current-context: arn:aws:eks:us-east-1:XXXXXXXXXXXX:cluster/bb-apps-devstg-eks-1ry
kind: Config
preferences: {}
users:
- name: arn:aws:eks:us-east-1:XXXXXXXXXXXX:cluster/bb-apps-devstg-eks-1ry
  user:
    exec:
      apiVersion: client.authentication.k8s.io/v1alpha1
      args:
      - --region
      - us-east-1
      - eks
      - get-token
      - --cluster-name
      - bb-apps-devstg-eks-1ry
      command: aws
      env:
      - name: AWS_PROFILE
        value: bb-apps-devstg-devops
      - name: AWS_CONFIG_FILE
        value: /Users/exequielbarrirero/.aws/bb/config
      - name: AWS_SHARED_CREDENTIALS_FILE
        value: /Users/exequielbarrirero/.aws/bb/credentials
```

3. Identities layers
   1. The main files begin with the `ids_` prefix.
      1. They declare roles and their respective policies.
      2. The former are intended to be assumed by pods in your cluster through the EKS IRSA feature.
   2. Go to this layer and run `leverage tf apply`

### K8s EKS Cluster Components and Workloads deployment

1. Cluster Components (`k8s-components`)
    1. Go to this layer and run `leverage tf init` & then `leverage tf apply`
    2. You can use the `terraform.tfvars` file to configure which components get installed
    3. Important: For private repo integrations after ArgoCD was successfully installed you will need to create this secret object in the cluster. Before creating the secret you need to update it to add the private SSH key that will grant ArgoCD permission to read the repository where the application definition files can be located. Note that this manual step is only a workaround that could be automated to simplify the orchestration.
2. Workloads (`k8s-workloads`)
    1. Go to this layer and run `leverage tf init` & then `leverage tf apply`

## Accessing the EKS Kubernetes resources (connectivity)
To access the Kubernetes resources using `kubectl` take into account that you need **connect
to the VPN** since all our implementations are via private endpoints (private VPC subnets).

### Connecting to ArgoCD
  1. Since we’re deploying a private K8s cluster you’ll need to be connected to the VPN
  2. From your web browser access to [https://argocd.devstg.aws.binbash.com.ar/](https://argocd.devstg.aws.binbash.com.ar/)
  3. Considering we are setting the initial [Bcrypt](https://pypi.org/project/bcrypt/) hashed admin password at [/k8-components/cicd-argo.tf](./k8s-components/cicd-argo.tf) definition.
     1. We pass the bcrypt password hash here`argocdServerAdminPassword = "$2b$12$xAsDJ6xtGby4MKHRbIEwSOrI5z14BUv20vY1d0VLN7Dqq/AC5ZUyG"`
     2. Based on the official [argocd repo readme](https://github.com/argoproj/argo-cd/blob/master/docs/faq.md#i-forgot-the-admin-password-how-do-i-reset-it) we'll describe below how to generate this password
        1. `$ pip install bcrypt`
        2. ```
           ╰─ python3
           Python 3.9.12 (main, Mar 26 2022, 15:51:15)
           >>> import bcrypt
           >>> passwd = b'argocd.serverAdminPassword'
           >>> hashed = bcrypt.hashpw(passwd, salt)
           >>> print(hashed)
           b'$2b$12$qwsPLT8MGNPM3GzBPCpqR.ginpexU6QXVhKqarq.dTyMPK8LQU9ZG'
           ```
  4. As Username, the default user is **admin**.
  5. You'll see the [EmojiVoto demo app](https://github.com/binbashar/le-demo-apps/tree/master/emojivoto/argocd) deployed and accessible at [https://emojivoto.devstg.aws.binbash.com.ar](https://emojivoto.devstg.aws.binbash.com.ar/)

## Post-initial Orchestration
After the initial orchestration, the typical flow could include multiple tasks. In other words, there won't be a normal flow but you some of the operations you would need to perform are:
- Update Kubernetes versions
- Update cluster components versions
- Add/remove/update cluster components settings
- Update network settings (e.g. toggle NAT Gateway, update Network ACLs, etc)
- Update IRSA roles/policies to grant/remove/fine-tune permissions

## TODO
- Look for TODO comments in this layer stack code in oder to find
  potential improvements that need to be addressed
- :warning: Please consider that only the current `terraform.tfvars` services
  set to `true` at the `k8s-components` and `k8s-workloads` layers are the only ones
  that have been fully tested
