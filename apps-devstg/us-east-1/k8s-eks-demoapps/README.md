# EKS Cluster reference layer

## Overview
This documentation should help you understand the different pieces that make up the EKS cluster.
With such understanding you should be able to create your copies of this
layer that are modified to serve other goals, such as having a platform per environment.

Terraform/OpenTofu code to orchestrate and deploy our EKS CLUSTER (cluster, network, k8s resources) reference
architecture. Consider that we already have an [AWS Landing Zone](https://github.com/binbashar/le-tf-infra-aws)
deployed as baseline which allow us to create, extend and enable new components on its grounds.

## Code Organization
The EKS layer (`apps-devstg/us-east-1/k8s-eks-demoapps`) is divided into sublayers which
have clear, specific purposes.

- `network/` is where we define the VPC resources for this cluster.
- `cluster/` is used to define the cluster attributes such as node groups and kubernetes version.
- `identities/` defines EKS IRSA roles that are later on assumed by roles running in the cluster.
- `addons/` is used to set different EKS managed Addons on the cluster.
- `k8s-components/` defines the base cluster components such as ingress controllers, certificate managers, dns managers, ci/cd components, and more.
- `secrets/` owns the AWS Secrets Manager entries the workloads read through External Secrets.
- `k8s-workloads/` defines the cluster workloads such as web-apps, apis, back-end microservices, etc.

## Orchestration
These are the steps to orchestrate the demoapps cluster. They can be used for spinning up the cluster and also for tearing it down if followed in reverse order.

### Pre-requisites
- The code is heavily organized around the Binbash Leverage -- it follows its conventions.
- EKS code is organized in the following sublayers:
    - `network`: VPC resources.
    - `cluster`: EKS cluster and nodes.
    - `identities`: EKS IRSA policies and roles.
    - `addons`: EKS add-ons.
    - `k8s-components`: cluster components for networking, monitoring, security, scaling, ci/cd, and more.
    - `secrets`: Secrets Manager entries consumed from the cluster via External Secrets. Only needed by the `google-microservices` demo app; apply it before `k8s-workloads`.
    - `k8s-workloads`: demo apps.
- The Binbash Leverage CLI must be installed and available in the system PATH.
- The same applies to `kubectl` and the `aws` CLI -- they are useful for troubleshooting.
- The code has been migrated to OpenTofu, therefore keep in mind the following:
    - You must use `leverage tofu *` commands for init, plan, and apply. The
      steps below write `leverage tf *` and `leverage terraform *`, which are
      aliases of that same wrapper.
    - Other commands are not proxied through `leverage`, just run `tofu` (which must be installed for that to work)
- Since the cluster API is configured to be privately accessible, VPN access is required. Prompt the user that as a reminder before you continue.

### Step 1
- Go to the `network` sublayer.
- Enable the NAT Gateway.
- Plan, verify, and apply.
- Applying takes usually takes 2-3 minutes. Be prepared.
- If the NAT Gateway is already deployed, that's fine, notify the user and move on.

### Step 2
- Go to the `cluster` sublayer.
- Plan, verify, and apply.
- Applying takes usually takes 15-25 minutes. Really prepare for that.
- This is the key step that requires VPN access. If that has not been covered applying may not succeed.

### Step 3
- Go to the `identities` sublayer.
- Plan, verify, and apply.

### Step 4
- Go to the `addons` sublayer.
- Plan, verify, and apply.

### Step 5
- Go to the `k8s-components` sublayer.
- This sublayer usually requires more involvement from the user to customize which components he wants to deploy.
- Prompt the user if he would like an standard setup (using `terraform.tfvars` defaults) or a custom one. If he chooses the latter, guide the user through the process of choosing which components to enable and install.
- Plan, verify, and apply.
- Applying this might take several minutes, depending on the components that need to be installed. Really prepare for that.
- There might be dependencies between some of the components. For instance, maybe an autoscaler will be needed first if there is another component that deploys too many pods or pods that require high resources usage.

### Step 6
- Go to the `secrets` sublayer and apply it.
- Only `google-microservices` needs it, through an `ExternalSecret` that reads `/k8s-eks-demoapps/test-secrets`. Skip it and that app's `paymentservice` never starts.

### Step 7
- Go to the `k8s-workloads` sublayer.
- This layer is optional. Prompt the user on whether he would like to install it.
- This layer depends on several cluster components in order to fully work. Two of the three demo apps are Argo CD `Application`s, and their `kubernetes_manifest` resources validate against the live API at *plan* time — so `k8s-components` must have installed Argo CD before this layer can even be planned.
- The endpoints created for the demo apps are private so VPN access is required.
- Plan, verify, and apply.
- See `k8s-workloads/README.md` for what each app needs and how to smoke-test it.

## Creating a new cluster using the existing setup as reference
The typical use cases would be:
- You need to set up a new platform in a new account
- Or you need to set up another platform in an existing account which already has a platform

Below we'll cover the first case but we'll assume that we are creating the `prd` platform from the code that
defines the `devstg` one:
1. First, you would copy-paste an existing EKS CLUSTER layer along with all its sublayers: `cp -r apps-devstg/us-east-1/k8s-eks-demoapps apps-prd/us-east-1/k8s-eks-demoapps`
2. Then, you need to go through each layer, open up the `config.tf` file and replace any occurrences of `devstg` with `prd`.
   1. There should be a `config.tf` in each sublayer so please make sure you cover all of them.
   2. Note you can use something like this from the layer directory: `find . -name '*.tf' -exec sed 's/devstg/prd/' -i {} \;`

Now that you created the layers for the platform you need to create a few other layers in the
new account that the cluster layers depend on, they are:

3. The `security-keys` layer
    - This layer creates a KMS key that we use for encrypting EKS state.
    - The procedure to create this layer is similar to the previous steps. You need to copy the layer from the `devstg` account and adjust its files to replace occurrences of `devstg` with `prd`.
    - Finally you need to run the Terraform Workflow (init and apply).
4. The `security-certs` layer
    - This layer creates the AWS Certificate Manager certificates that are used by the AWS ALBs that are created by the ALB Ingress Controller.
    - A similar procedure to create this layer. Get this layer from `devstg`, replace references to `devstg` with `prd`, and then run init & apply.

### Create the EKS CLUSTER
The basic flow is:

- Base EKS
  - apply network
    - you should create a VPC peering from `shared` account (peering config will be stored in `shared/<region>/base-network` layer)
  - add the VPC CIDR to your VPN server (e.g. Pritunl)
  - apply cluster
  - apply identities
  - apply addons
- Stuff on top of EKS
  - apply components
  - apply workloads

Following the [leverage terraform workflow](https://leverage.binbash.com.ar/user-guide/ref-architecture-aws/workflow/)
The EKS CLUSTER layers need to be orchestrated in the following order:

#### The base
1. Network
    1. Open the `locals.tf` file and make sure the VPC CIDR and subnets are correct.
       1. Check the CIDR/subnets definition that were made for DevStg and Prd clusters and avoid segments overlapping.
    2. In the same `locals.tf` file, there is a "VPC Peerings" section.
       1. Make sure it contains the right entries to match the VPC peerings that you actually need to set up.
    3. In the `variables.tf` file you will find several variables you can use to configure multiple settings.
       1. For instance, if you anticipate this cluster is going to be permanent, you could set the `vpc_enable_nat_gateway` flag to `true` (you could also do that by updating the `terraform.tfvars` in the same folder);
          1. Note this value has to be `true` when installing the cluster, otherwise the nodes won´t be created
       2. or if you are standing up a production cluster, you may want to set `vpc_single_nat_gateway` to `false` in order to have a NAT Gateways per availability zone.
    4. **Apply the layer**: `leverage tf apply`
    5. For this network to be accessible from VPN, we need to peer it with `shared` networks, to do this see step 5 under ["Create Network layer" title in this document](https://leverage.binbash.co/try-leverage/add-aws-accounts/#create-the-network-layer).
    6. Add your VPC CIDR to the VPN Server

2. Cluster
    1. Since we’re deploying a private K8s cluster you’ll need to be **connected to the VPN**
    2. Check out the `variables.tf` file to configure the Kubernetes version or whether you want to create a cluster with a public endpoint (in most cases you don't but the possibility is there).
    3. Open up `locals.tf` and make sure the `map_accounts`, `map_users` and `map_roles` variables define the right accounts, users and roles that will be granted permissions on the cluster.
    4. Then open `eks-workers-managed.tf` to set the node groups and their attributes according to your requirements.
       1. In this file you can also configure security group rules, both for granting access to the cluster API or to the nodes.
    5. **Apply the layer**: `leverage tf apply`
    6. In the output you should see the credentials you need to talk to Kubernetes API via kubectl (or other clients).

        ```shell
        apps-devstg//k8s-eks-demoapps/cluster$ leverage terraform output

        ...
        kubectl_config = apiVersion: v1
        preferences: {}
        kind: Config

        clusters:
        - cluster:
            server: https://9E9E4XXXXXXXXXXXXXXXEFC1F00.gr7.us-east-1.eks.amazonaws.com
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

    7. Note you can use the [binbash Leverage kubectl command](https://leverage.binbash.co/user-guide/leverage-cli/reference/kubectl/) to access the cluster (you need to connect to the VPN first) or connect manually as follows:
        1. Connecting to the K8s EKS cluster
        2. Since we’re deploying a private K8s cluster you’ll need to be **connected to the VPN**
        3. install `kubetcl` in your workstation
            1. https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/#install-using-native-package-management
            2. https://kubernetes.io/docs/tasks/tools/install-kubectl-macos/#install-with-homebrew-on-macos
            3. 📒 NOTE: consider using `kubectl` version 1.27 or 1.28 (not latest, in any case check the cluster version first)
        4. install `iam-authenticator` in your workstation
            1. https://docs.aws.amazon.com/eks/latest/userguide/install-aws-iam-authenticator.html
        5. Export AWS credentials
           1. `export AWS_SHARED_CREDENTIALS_FILE="~/.aws/bb/credentials"`
           2. `export AWS_CONFIG_FILE="~/.aws/bb/config"`
        6. `k8s-eks-demoapps/cluster` layer should generate the `kubeconfig` file in the output of the apply, or by running `leverage tf output` similar to https://github.com/binbashar/le-devops-workflows/blob/master/README.md#eks-clusters-kubeconfig-file
            1. Edit that file to replace $HOME with the path to your home dir
            2. Place the kubeconfig in `~/.kube/bb/apps-devstg` and then use export `KUBECONFIG=~/.kube/bb/apps-devstg` to help tools like kubectl find a way to talk to the cluster (or `KUBECONFIG=~/.kube/bb/apps-devstg get pods --all-namespaces` )
            3. You should be now able to run kubectl  commands (https://kubernetes.io/docs/reference/kubectl/cheatsheet/)

3. Identities layers
   1. The main files begin with the `ids_` prefix.
      1. They declare roles and their respective policies.
      2. The former are intended to be assumed by pods in your cluster through the EKS IRSA feature.
   2. **Apply the layer**: `leverage tf apply`

4. Addons layers
   1. Check the Addons versions in `locals.tf` file, they should fit the Kubernetes version in the cluster.
   2. Add or remove Addons as per your needs.
       1. Note some Addons relies on identities created in the Identities layer, so if you add or remove Addons maybe you need to add or remove identities.
   3. **Apply the layer**: `leverage tf apply`

#### EKS CLUSTER's K8s EKS Cluster Components and Workloads deployment
1. Cluster Components (k8s-components)
    1. Note that EKS CLUSTER has a set of default components, anyway you can use the `terraform.tfvars` file to configure which components get installed
    2. Important: For private repo integrations after ArgoCD was successfully installed you will need to create this secret object in the cluster. Before creating the secret you need to update it to add the private SSH key that will grant ArgoCD permission to read the repository where the application definition files can be located. Note that this manual step is only a workaround that could be automated to simplify the orchestration.
    3. **Apply the layer**: `leverage tf apply`


2. Workloads (k8s-workloads)
    1. **Apply the layer**: `leverage tf apply`

## Accessing the EKS Kubernetes resources (connectivity)
To access the Kubernetes resources using `kubectl` take into account that you need **connect
to the VPN** since all our implementations are via private endpoints (private VPC subnets).

Note you can use the [binbash Leverage kubectl command](https://leverage.binbash.co/user-guide/leverage-cli/reference/kubectl/) to access the cluster.

### Connecting to ArgoCD
1. Since we’re deploying a private K8s cluster you’ll need to be connected to the VPN
2. From your web browser access to https://argocd.aws.binbash.com.ar/
3. Username is **admin**. The password is *not* the chart's generated one —
    `configs.secret.argocdServerAdminPassword` is set from the
    `/k8s-eks-demoapps/argocdserveradminpassword` secret in AWS Secrets Manager,
    which holds a bcrypt hash. Get the plaintext from whoever provisioned it;
    `argocd-initial-admin-secret` is not created when the password is supplied
    this way.
4. For the CLI, `--grpc-web` is required — see `k8s-components/README.md`:
    `argocd login argocd.aws.binbash.com.ar --grpc-web`

### Ingress and exposing apps
All L7 exposure goes through Envoy Gateway, not Ingress. See
[`k8s-components/README.md`](k8s-components/README.md) for the topology, how to
publish an app on the private or public gateway, and the operational gotchas.

## Post-initial Orchestration
After the initial orchestration, the typical flow could include multiple tasks. In other words, there won't be a normal flow but you some of the operations you would need to perform are:
- Update Kubernetes versions
- Update cluster components versions
- Add/remove/update cluster components settings
- Update network settings (e.g. toggle NAT Gateway, update Network ACLs, etc)
- Update IRSA roles/policies to grant/remove/fine-tune permissions
