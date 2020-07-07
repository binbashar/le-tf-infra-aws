<div align="center">
    <img src="https://raw.githubusercontent.com/binbashar/bb-devops-tf-aws-kops/master/figures/binbash.png" alt="drawing" width="350"/>
</div>
<div align="right">
  <img src="https://raw.githubusercontent.com/binbashar/bb-devops-tf-aws-kops/master/figures/binbash-leverage-terraform.png"
  alt="leverage" width="230"/>
</div>

# Reference Architecture: Terraform AWS Kubernetes Kops Cluster

## Kops Pre-requisites

### Overview
K8s clusters provisioned by Kops have a number of resources that need to be available before the
cluster is created. These are Kops pre-requisites and they are defined in the `1-prerequisites`
directory which includes all Terraform files used to create/modify these resources.

**IMPORTANT:** The current code has been fully tested with the AWS VPC Network Module
https://github.com/binbashar/terraform-aws-vpc

## Leverage Documentation

- **How it works**
    - [Overview](https://leverage.binbash.com.ar/how-it-works/compute/overview/)
    - [K8s Kops](https://leverage.binbash.com.ar/how-it-works/compute/k8s-kops/)
- **User guide**
    1. [Configurations](https://leverage.binbash.com.ar/user-guide/base-configuration/repo-le-tf-infra-aws/)
    2. [Workflow](https://leverage.binbash.com.ar/user-guide/base-workflow/repo-le-tf-infra-aws/)
    3. [K8s Kops](https://leverage.binbash.com.ar/user-guide/compute/k8s-kops/)
