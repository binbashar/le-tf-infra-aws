# Kubernetes: DevStg Cluster

## Kops Pre-requisites

### Overview
K8s clusters provisioned by Kops have a number of resources that need to be available before the cluster is created. These are Kops pre-requisites and they are defined in the `1-prerequisites` directory which includes all Terraform files used to create/modify these resources.

### Workflow
The workflow follows the same approach that is used to manage other resources in this account. E.g. network, identities, and so on.


## Kops Cluster Management
The `2-kops` directory includes helper scripts and Terraform files ...

### Overview
Cluster Management via Kops is typically carried out through the kops CLI. In this case, we use a `2-kops` directory that contains a Makefile, Terraform files and other helper scripts that reinforce the workflow we use to create/update/delete the cluster.

### Workflow
This workflow is a little different to the typical Terraform workflows we use. The full workflow goes as follows:
1. Modify files under `1-prerequisites`
  * Mostly before the cluster is created but could be needed afterward
2. Modify `cluster-template.yml`
  * E.g. to add or remove instance groups, upgrade k8s version, etc
3. Run `make cluster-update`
  * Get Terraform outputs from `1-prerequisites`
  * Generate a Kops cluster manifest -- it uses `cluster-template.yml` as a template and the outputs from the point above as replacement values
  * Update Kops state -- it uses the generated Kops cluster manifest in previous point (`cluster.yml`)
  * Generate Kops Terraform file -- this file represents the changes that Kops needs to apply on the cloud provider
4. Run `make plan`
  * To preview any infrastructure changes that Terraform will make
5. Run `make apply`
  * To apply those infrastructure changes
6. Run `make cluster-rolling-update`
  * To determine if Kops needs to trigger some changes to happen right now
  * These are usually changes to the EC2 instances that won't get reflected as they depend on the autoscaling
7. Run `make cluster-rolling-update-yes`
  * To actually make any changes to the cluster masters/nodes happen

The workflow may look complicated at first but generally it boils down to these simplified steps:
1. Modify `cluster-template.yml`
2. Run `make cluste-update`
3. Run `make apply`
4. Run `make cluster-rolling-update-yes`
