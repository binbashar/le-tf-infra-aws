<div align="center">
    <img src="./%40figures/binbash.png" alt="drawing" width="350"/>
</div>
<div align="right">
  <img src="./%40figures/binbash-leverage-terraform.png"
  alt="leverage" width="230"/>
</div>

# Reference Architecture: Terraform AWS Infrastructure

## Overview
This repository contains all Terraform configuration files used to create Binbash Leverage Reference AWS Cloud 
Solutions Architecture.

## Files/Folders Organization
The following block provides a brief explanation of the chosen files/folders layout:

```
+ apps-devstg/     (resources for Apps dev & stg account)
    ...
+ apps-prd/        (resources for Apps Prod account)
    ...
+ root-org/        (resources for the root-org account)
    ...
+ security/        (resources for the security + users account)
    ...
+ shared/          (resources for the shared account)
    ...
```

Configuration files are organized by environments (e.g. dev, stg) and service type (identities, sec, 
network, etc) to keep any changes made to them separate.
Within each of those folders you should find the Terraform files that are used to define all the 
resources that belong to such environment.

<div align="center">
  <img src="./%40figures/binbash-aws-organizations.png"
  alt="leverage" width="1000"/>
</div>

**figure 1:** AWS Organization Architecture Diagram (just as reference).

Under every account folder you will see a service layer structure similar to the following:
```
.
├── apps-devstg
│   ├── 10_databases_mysql --
│   ├── 10_databases_pgsql --
│   ├── 1_tf-backend
│   ├── 2_identities
│   ├── 3_network
│   ├── 4_security
│   ├── 4_security_compliance --
│   ├── 5_dns
│   ├── 6_notifications --
│   ├── 7_cloud-nuke
│   ├── 8_k8s_eks --
│   ├── 8_k8s_kops --
│   ├── 9_backups --
│   ├── 9_storage --
│   └── config
├── apps-prd
│   ├── 1_tf-backend
│   ├── 2_identities
│   ├── 3_network
│   ├── 4_security
│   ├── 4_security_compliance --
│   ├── 5_dns
│   └── config
├── root-org
│   ├── 1_tf-backend
│   ├── 2_cost-mgmt
│   ├── 3_security
│   ├── 3_security_compliance --
│   ├── 4_notifications
│   └── config
├── security
│   ├── 1_tf-backend
│   ├── 2_secrets
│   ├── 3_identities
│   ├── 4_security
│   ├── 4_security_compliance --
│   └── config
└── shared
    ├── 1_tf-backend
    ├── 2_identities
    ├── 3_network
    ├── 4_security
    ├── 4_security_compliance --
    ├── 5_dns
    ├── 6_notifications --
    ├── 7_vpn-server
    ├── 8_jenkins-vault --
    ├── 9_container_registry
    └── config
```

**NOTE:** As a convention folders with the `--` suffix reflect that the resources are not currently
created in AWS, basically they've been destroyed or not yet exist. 

Such separation is meant to avoid situations in which a single folder contains a lot of resources. 
That is important to avoid because at some point, running `terraform plan or apply` stats taking too long and that 
becomes a problem.

This organization also provides a layout that is easier to navigate and discover. 
You simply start with the accounts at the top level and then you get to explore the resource categories within 
each account.


## Pre-requisites

### Makefile
- We rely on `Makefiles` as a wrapper to run terraform commands that consistently use the same config files.
- You are encouraged to inspect those Makefiles to understand what's going on.

### Terraform
- Install terraform >= v0.12.20
  - Run `terraform version` to check
  - NOTE: Most `Makefiles` already grant the recs via Dockerized cmds (https://hub.docker.com/repository/docker/binbash/terraform-resources)  

### Remote State
In the `tf-backend` folder you should find all setup scripts or configuration files that need to be run before
 you can get to work with anything else.

*IMPORTANT:* THIS IS ONLY NEEDED IF THE BACKEND WAS NOT CREATED YET. IF THE BACKEND ALREADY EXISTS YOU JUST USE IT.

### Configuration
- Config files can be found in under each 'config' folder.
- File `backend.config` contains TF variables that are mainly used to configure TF backend but since
 `profile` and `region` are defined there, we also use them to inject those values into other TF commands.
- File `base.config` contains TF variables that we inject to TF commands such as plan or apply and which 
cannot be stored in `backend.config` due to TF restrictions.
- File `extra.config` similar to `base.config` but variables declared here are not used by all sub-directories.

### AWS Profile
- File `backend.config` will inject the profile name that TF will use to make changes on AWS.
- Such profile is usually one that relies on another profile to assume a role to get access to each corresponding account.
- Read the following page to understand how to set up a profile to assume 
a role => https://docs.aws.amazon.com/cli/latest/userguide/cli-roles.html

## Workflow

### Terraform Workflow
1. Make sure you've read the 'Pre-requisites' section 1st steps
2. Get into the folder that you need to work with (e.g. `2_identities`)
3. Run `make init`
4. Make whatever changes you need to make
5. Run `make plan` if you only mean to preview those changes
6. Run `make apply` if you want to review and likely apply those changes

**NOTE:** If desired at step **#5** you could submit a PR, allowing you and the rest of the team to 
understand and review what changes would be made to your AWS Cloud Arctecture components before excecuting 
`make apply` (`terraform apply`). This brings the huge benefit of treating changes with a **GitOps** oriented 
approach, basically as we should treat any other code & infrastructure change, and integrate it with the 
rest of our tools and practices like CI/CD, integration testing, replicate environments and so on.

## Read more
Make sure you check out the [documentation](@docs/index.html) in the docs directory.

Moreover, consider some official AWS docs, blog post and whitepapers we've considered for the current 
Reference Solutions Architecture desing:
- **CloudTrail for AWS Organizations:** https://docs.aws.amazon.com/awscloudtrail/latest/userguide/creating-trail-organization.html
- **Reserved Instances - Multi Account:** https://aws.amazon.com/about-aws/whats-new/2019/07/amazon-ec2-on-demand-capacity-reservations-shared-across-multiple-aws-accounts/
- **AWS Multiple Account Security Strategy:** https://d0.awsstatic.com/aws-answers/AWS_Multi_Account_Security_Strategy.pdf
- **AWS Multiple Account Billing Strategy:** https://aws.amazon.com/answers/account-management/aws-multi-account-billing-strategy/
- **AWS Secure Account Setup:** https://aws.amazon.com/answers/security/aws-secure-account-setup/
- **Authentication and Access Control for AWS Organizations:** https://docs.aws.amazon.com/organizations/latest/userguide/orgs_permissions.html
- **AWS Regions:** https://www.concurrencylabs.com/blog/choose-your-aws-region-wisely/
- **VPC Peering:** https://docs.aws.amazon.com/vpc/latest/peering/what-is-vpc-peering.html
- **Route53 DNS VPC Associations:** https://aws.amazon.com/premiumsupport/knowledge-center/private-hosted-zone-different-account/
- **AWS Well Architected Framework:** https://aws.amazon.com/blogs/apn/the-5-pillars-of-the-aws-well-architected-framework/
- **AWS Tagging strategies:** https://aws.amazon.com/answers/account-management/aws-tagging-strategies/ 
- **Inviting an AWS Account to Join Your Organization**: https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_invites.html


## TODO
- https://trello.com/c/hP2XTiDM/106-ref-architecture-markdown-html-documentation
- https://trello.com/c/H2bRh6QA/19-ref-architecture-1st-stage-design-reference-architecture-for-dev-stg-and-prod-envs-aws-organizations-based-approach

---

# Release Management

## Docker based makefile commands

* <https://cloud.docker.com/u/binbash/repository/docker/binbash/git-release>
* <https://github.com/binbashar/bb-devops-tf-infra-aws/blob/master/Makefile>

Root directory `Makefile` has the automated steps (to be integrated with **CircleCI jobs** []() )

### CircleCi PR auto-release job

<div align="left">
  <img src="./%40figures/circleci.png" alt="leverage-circleci" width="230"/>
</div>

- <https://circleci.com/gh/binbashar/bb-devops-tf-infra-aws>
- **NOTE:** Will only run after merged PR.

### Manual execution from workstation

```
$ make
Available Commands:
 - release-major-with-changelog make changelog-major && git add && git commit && make release-major
 - release-minor-with-changelog make changelog-minor && git add && git commit && make release-minor
 - release-patch-with-changelog make changelog-patch && git add && git commit && make release-patch
