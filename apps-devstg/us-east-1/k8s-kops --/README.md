<div align="center">
    <img src="../../%40doc/figures/binbash.png"
    alt="binbash" width="250"/>
</div>
<div align="right">
  <img src="../../%40doc/figures/binbash-leverage-terraform.png"
  alt="leverage" width="130"/>
</div>

# Reference Architecture: Terraform AWS Kubernetes Kops Cluster

## Kops Pre-requisites

To develop this Kops K8s Cluster you need a VPC (with private/public subnets and NAT gateway enabled) to create the cluster in.

!!! Info
    If you want Karpeneter enabled the subnets on which the cluster will be deployed need to have these tags:

    ```
    "kops.k8s.io/instance-group/nodes"                     = "true"
    "kubernetes.io/cluster/cluster01-kops.devstg.k8s.local" = "true"
    ```

    Note you have to set your cluster name in the tag.

### Overview

K8s clusters provisioned by Kops have a number of resources that need to be available before the
cluster is created. These are Kops pre-requisites and they are defined in the `1-prerequisites`
directory which includes all Terraform files used to create/modify these resources.

## Steps to create it

1. Set up and apply prerequisites layers
2. In 2-kops
  - create the cluster definition
  - apply layer
  - get the KUBECONFIG file
3. get the KUBECONFIG file, set up and apply the layer

### 1 - prerequisites

Edit the `locals.tf` file.

Edit the cluster name:

``` hcl
  base_domain_name = "k8s.local"
  k8s_cluster_name = "cluster01-kops.${local.short_environment}.${local.base_domain_name}"
```

Note the `k8s.local` base domain will force the creation of a "gossip cluster", i.e. a private cluster.

In this case you'll need to be inside the VPN to reach the API and will need to create a LB to access your apps.

Set the type and number of master and worker nodes:

``` hcl
  # K8s Kops Master Nodes Machine (EC2) type and size + ASG Min-Max per AZ
  # then min/max = 1 will create 1 Master Node x AZ => 3 x Masters
  kops_master_machine_type     = "t3.medium"
  kops_master_machine_max_size = 1
  kops_master_machine_min_size = 1

  # K8s Kops Worker Nodes Machine (EC2) type and size + ASG Min-Max
  kops_worker_machine_type     = "t3.medium"
  kops_worker_machine_max_size = 5
  kops_worker_machine_min_size = 1
  # If you use Karpenter set the list of types here
  kops_worker_machine_types_karpenter = ["t2.medium", "t2.large", "t3.medium", "t3.large", "t3a.medium", "t3a.large", "m4.large"]
```

Note the last variable is for Karpenter. If Karpenter is enabled the `kops_worker_machine_*` are not used.

Set the number of AZs on which the master nodes will be spread:

``` hcl
  number_of_cluster_master_azs = 1
```

Then, go around the other variables and set them as per your needs.

Apply it as usual:

``` shell
leverage tf apply
```

#### Note on VPCs

In the `config.tf` file you'll find:

``` hcl
data "terraform_remote_state" "vpc" {
  backend = "s3"

  config = {
    region  = var.region
    profile = var.profile
    bucket  = var.bucket
    key     = "${var.environment}/ca-central-1/kops-network/terraform.tfstate"
  }
}

data "terraform_remote_state" "vpc-shared" {
  backend = "s3"

  config = {
    region  = var.region
    profile = "${var.project}-shared-devops"
    bucket  = "${var.project}-shared-terraform-backend"
    key     = "shared/us-east-1/network/terraform.tfstate"
  }
}
```

These are the remote states for the "vpc", the vpc in which the cluster will be created, and the "vpc-shared", the vpc in wich the VPN Server is working, so we can accept connections from there.


#### Note on Karpenter

To use Karpeneter you need to create a service linked role so spot can be used.


```shell
aws iam create-service-linked-role --aws-service-name spot.amazonaws.com
```

### 2 - kops

Create the cluster definition:

``` shell
make cluster-update
```

Apply the layer:

``` shell
leverage tf apply
```

Get the Kubeconfig:

``` shell
make kops-kubeconfig
```

The KUBECONFIG will be saved to a file named same as the cluster. E.g. `cluster01-kops.devstg.k8s.local`.

So you can:

``` shell
export KUBECONFIG=/path/to/your/file/cluster01-kops.devstg.k8s.local
```

...and once the cluster is up and running (and you are in the VPN), you'll be able to access the cluster!

### 3 - extras

You have to copy the KUBECONFIG file from the previous step and set the name in the `config.tf` file:

``` hcl
provider "kubernetes" {
  config_path    = "cluster01-kops.devstg.k8s.local"
  config_context = "cluster01-kops.devstg.k8s.local"
}

provider "helm" {
  kubernetes {
  config_path    = "cluster01-kops.devstg.k8s.local"
  config_context = "cluster01-kops.devstg.k8s.local"
  }
}
```

Now set and apply the layer.

``` shell
leverage tf apply
```

Note Traefik is set as default. It will create a public LB.

Also note a file called `route53record.tf` will create a record in Route53 pointing to the LB.

Since this is set using the standard Leverage setup, you'll find in the `config.tf` file the remote state for the DNS:

``` hcl
data "terraform_remote_state" "shared-dns" {
  backend = "s3"

  config = {
    region  = var.region
    profile = "${var.project}-shared-devops"
    bucket  = "${var.project}-shared-terraform-backend"
    key     = "shared/global/dns/binbash.co/terraform.tfstate"
  }
}
```


## Leverage Documentation

- **Binbash Leverage Cookbook**
    - [K8s KOPS Cookbook](https://leverage.binbash.co/user-guide/cookbooks/k8s/)
- **How it works**
    - [Overview](https://leverage.binbash.com.ar/how-it-works/compute/overview/)
    - [K8s Kops](https://leverage.binbash.com.ar/how-it-works/compute/k8s-kops/)
- **User guide**
    1. [Configurations](https://leverage.binbash.com.ar/user-guide/base-configuration/repo-le-tf-infra-aws/)
    2. [Workflow](https://leverage.binbash.com.ar/user-guide/base-workflow/repo-le-tf-infra-aws/)
    3. [K8s Kops](https://leverage.binbash.com.ar/user-guide/compute/k8s-kops/)
