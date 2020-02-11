<div align="center">
    <img src=".%40doc/figures/binbash.png" alt="drawing" width="350"/>
</div>
<div align="right">
  <img src=".%40doc/figures/binbash-leverage-terraform.png"
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
  <img src=".%40doc/figures/binbash-aws-organizations.png"
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
│   ├── 6_notifications
│   ├── 7_cloud-nuke
│   ├── 8_k8s_eks --
│   ├── 8_k8s_kops --
│   ├── 9_backups --
│   ├── 9_storage --
│   └── config
├── apps-prd
│   ├── 1_tf-backend --
│   ├── 2_identities --
│   ├── 3_network --
│   ├── 4_security --
│   ├── 4_security_compliance --
│   ├── 5_dns --
│   ├── 6_notifications --
│   ├── 9_backups --
│   └── config
├── root-org
│   ├── 1_tf-backend
│   ├── 2_identities
│   ├── 3_organizations
│   ├── 4_security
│   ├── 4_security_compliance --
│   ├── 5_cost-mgmt
│   ├── 6_notifications
│   └── config
├── security
│   ├── 1_tf-backend
│   ├── 2_identities
│   ├── 4_security
│   ├── 4_security_compliance --
│   ├── 6_notifications
│   └── config
└── shared
    ├── 1_tf-backend
    ├── 2_identities
    ├── 3_network
    ├── 4_security
    ├── 4_security_compliance --
    ├── 5_dns
    ├── 6_notifications
    ├── 7_vpn-server
    ├── 8_container_registry
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
- File `@doc/binbash-aws-org-config` will be considered to be appended to your `.aws/config` file 
note that `.aws/config` will depend on the IAM profiles declared at your `.aws/credentials` 
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

---

## Reference Architecture Design

### Identity and Access Management (IAM) Layer
#### Summary

Having this official AWS resource as reference https://d0.awsstatic.com/aws-answers/AWS_Multi_Account_Security_Strategy.pdf
we've define a security account structure for managing multiple accounts.

* No IAM accounts will be created, except in the Security/Users account. 
* All access to resources within Client organization will be assigned via IAM policy documents attached 
to IAM roles or IAM groups.
* All IAM roles and IAM groups will have the least privileges required to function.
* IAM AWS managed and customer managed policies will be defined, inline policies will be avoided 
whenever possible.
* All user management will be maintained as code and will reside in this repository.
* All users will have MFA enabled whenever possible.
* Root user credentials will be rotated and secured. MFA for root will be enabled. 
* IAM Access Keys for root will be disabled.

Creating a security relationship between  accounts makes it even easier for companies to assess the security 
of AWS-based deployments, centralize security monitoring and management, manage identity and access, and provide 
audit and compliance monitoring services:

<div align="center">
  <img src=".%40doc/figures/binbash-aws-iam.png"
  alt="leverage" width="700"/>
</div>

**figure 2:** AWS Organization Security account structure for managing multiple accounts (just as reference).

### Network Layer

In this section we detail all the network design related specifications:
* VPCs CIDR blocks
* VPC Gateways:  Internet, NAT, VPN.
* VPC Peerings
* VPC DNS Private Hosted Zones Associations.
* Network ACLS (NACLs)

#### VPCs IP Addressing Plan (CIDR blocks sizing)
##### Introduction
VPCs can vary in size from 16 addresses (/28 netmask) to 65,536 addresses (/16 netmask). 
In order to size a VPC correctly, it is important to understand the number, types, and sizes of workloads 
expected to run in it, as well as workload elasticity and load balancing requirements. 

Keep in mind that there is no charge for using Amazon VPC (aside from EC2 charges), therefore cost 
should not be a factor when determining the appropriate size for your VPC, so make sure you size your 
VPC for growth.

Moving workloads or AWS resources between networks is not a trivial task, so be generous in your 
IP address estimates to give yourself plenty of room to grow, deploy new workloads, or change your 
VPC design configuration from one to another. The majority of AWS customers use VPCs with a /16 
netmask and subnets with /24 netmasks. The primary reason AWS customers select smaller VPC and 
subnet sizes is to avoid overlapping network addresses with existing networks. 

So having https://aws.amazon.com/answers/networking/aws-single-vpc-design/ we've choosen
a Medium/Small VPC/Subnet addressing plan which would probably fit a broad range variety of
use cases:

* AWS Org IP Addressing calculation is presented below based on segment `172.16.0.0.0/12`.
* We started from `172.16.0.0.0/12` and subnetted to `/20` 
  * resulting in Total Subnets: 256 ⇒ 1 x AWS Account with Hosts/SubNet: 4094.
* Then each of these are /20 to /23 
  * resulting in Total Subnets: 12 ⇒ 1 x AWS VPC with Hosts/Net: 256.
  * eg: us-east-1 w/ 6 AZs -> 6 x Private Subnets /az + 6 x Publuc Subnets /az

### VPC Shared Account
The CIDR block of the VPC

**vpc_cidr_block = "172.18.0.0/20"**
```
Network:   172.18.0.0/20        10101100.00010010.0000 0000.00000000
HostMin:   172.18.0.1           10101100.00010010.0000 0000.00000001
HostMax:   172.18.15.254        10101100.00010010.0000 1111.11111110
Broadcast: 172.18.15.255        10101100.00010010.0000 1111.11111111
Hosts/Net: 4094                  Class B, Private Internet
```

List of secondary CIDR blocks of the VPC (**reserved for future use**)
**vpc_secondary_cidr_blocks** = ["172.18.16.0/20"]
```
Network:   172.18.16.0/20       10101100.00010010.0001 0000.00000000
HostMin:   172.18.16.1          10101100.00010010.0001 0000.00000001
HostMax:   172.18.31.254        10101100.00010010.0001 1111.11111110
Broadcast: 172.18.31.255        10101100.00010010.0001 1111.11111111
Hosts/Net: 4094                  Class B, Private Internet
```

### VPC Apps DevStg Account
The CIDR block of the VPC

**vpc_cidr_block = "172.18.32.0/20"**
```
Network:   172.18.32.0/20       10101100.00010010.0010 0000.00000000
HostMin:   172.18.32.1          10101100.00010010.0010 0000.00000001
HostMax:   172.18.47.254        10101100.00010010.0010 1111.11111110
Broadcast: 172.18.47.255        10101100.00010010.0010 1111.11111111
Hosts/Net: 4094                  Class B, Private Internet
```

List of secondary CIDR blocks of the VPC (**reserved for future use**)
**vpc_secondary_cidr_blocks** = ["172.18.48.0/20"]
```
Network:   172.18.48.0/20       10101100.00010010.0011 0000.00000000
HostMin:   172.18.48.1          10101100.00010010.0011 0000.00000001
HostMax:   172.18.63.254        10101100.00010010.0011 1111.11111110
Broadcast: 172.18.63.255        10101100.00010010.0011 1111.11111111
Hosts/Net: 4094                  Class B, Private Internet
```

### VPC Apps Prd Account
The CIDR block of the VPC

**vpc_cidr_block = "172.18.64.0/20"**
```
Network:   172.18.64.0/20       10101100.00010010.0100 0000.00000000
HostMin:   172.18.64.1          10101100.00010010.0100 0000.00000001
HostMax:   172.18.79.254        10101100.00010010.0100 1111.11111110
Broadcast: 172.18.79.255        10101100.00010010.0100 1111.11111111
Hosts/Net: 4094                  Class B, Private Internet
```

List of secondary CIDR blocks of the VPC (**reserved for future use**)
**vpc_secondary_cidr_blocks** = ["172.18.80.0/20"]
```
Network:   172.18.80.0/20       10101100.00010010.0101 0000.00000000
HostMin:   172.18.80.1          10101100.00010010.0101 0000.00000001
HostMax:   172.18.95.254        10101100.00010010.0101 1111.11111110
Broadcast: 172.18.95.255        10101100.00010010.0101 1111.11111111
Hosts/Net: 4094                  Class B, Private Internet
```

### VPC N° and DR - reserverd for Disaster Recovery (DR) Segments and future use
If you need a DR strategy please consider planning and assigning the proper 
segments from this reserved pool.
```
Network:   172.18.96.0/20       10101100.00010010.0110 0000.00000000
HostMin:   172.18.96.1          10101100.00010010.0110 0000.00000001
HostMax:   172.18.111.254       10101100.00010010.0110 1111.11111110
Broadcast: 172.18.111.255       10101100.00010010.0110 1111.11111111
Hosts/Net: 4094                  Class B, Private Internet

...

Network:   172.18.176.0/20      10101100.00010010.1011 0000.00000000
HostMin:   172.18.176.1         10101100.00010010.1011 0000.00000001
HostMax:   172.18.191.254       10101100.00010010.1011 1111.11111110
Broadcast: 172.18.191.255       10101100.00010010.1011 1111.11111111
Hosts/Net: 4094                  Class B, Private Internet

...

 
Network:   172.31.240.0/20      10101100.00011111.1111 0000.00000000
HostMin:   172.31.240.1         10101100.00011111.1111 0000.00000001
HostMax:   172.31.255.254       10101100.00011111.1111 1111.11111110
Broadcast: 172.31.255.255       10101100.00011111.1111 1111.11111111
Hosts/Net: 4094                  Class B, Private Internet
```

#### CONSIDERATIONS
* Docker runs in the 172.17.0.0/16 CIDR range in Amazon EKS clusters. 
  We recommend that your cluster's VPC subnets do not overlap this range. Otherwise, you will 
  receive the following error:
  ```
  Error: : error upgrading connection: error dialing backend: dial tcp 172.17.nn.nn:10250: 
  getsockopt: no route to host
  ```
  (https://docs.aws.amazon.com/eks/latest/userguide/network_reqs.html)
   
  
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
  <img src=".%40doc/figures/circleci.png" alt="leverage-circleci" width="230"/>
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
