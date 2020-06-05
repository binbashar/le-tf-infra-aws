<div align="center">
    <img src="https://raw.githubusercontent.com/binbashar/bb-devops-tf-aws-organizations/master/figures/binbash.png" alt="drawing" width="350"/>
</div>
<div align="right">
  <img src="https://raw.githubusercontent.com/binbashar/bb-devops-tf-aws-organizations/master/figures/binbash-leverage-terraform.png"
  alt="leverage" width="230"/>
</div>

# Reference Architecture: Terraform AWS Organizations Account Baseline

## Overview
This repository contains all Terraform configuration files used to create Binbash Leverage Reference 
AWS Organizations Multi-Account baseline layout.


## AWS Organization Accounts Layout
The following block provides a brief explanation of the chosen AWS Organization Accounts layout:
```
+ devstg/          (resources for dev apps/services account)
    ...
+ prod/            (resources for prod apps/services account)
    ...
+ root-org/        (resources for the root-org account)
    ...
+ security/        (resources for the security + users account)
    ...
+ shared/          (resources for the shared account)
    ...
+ legacy/          (resources for the legacy/pre-existing account)
    ...
```

<div align="center">
  <img src="https://raw.githubusercontent.com/binbashar/bb-devops-tf-aws-organizations/master/figures/binbash-aws-organizations.png"
alt="leverage" width="1000"/>
</div>

**NOTE:** *Image just as reference*


### AWS Organization Accounts description
Our default AWS Organizations terraform layout solution includes 5 accounts + 1 to N (if you invite pre-existing AWS Account/s).


| Account                     | Description                                                                                                                                                                                                                                                                                |
|-----------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Root Organizations          | Used to manage configuration and access to AWS Org managed accounts. The AWS Organizations account provides the ability to create and financially manage member accounts, it contains AWS Organizations Service Control Policies(SCPs).                                                    |
| Shared Services / Resources | Reference for creating infrastructure shared services such as directory services, DNS, VPN Solution, Monitoring tools like Prometheus and Graphana, CI/CD server (Jenkins, Drone, Spinnaker, etc), centralized logging solution like ELK  and Vault Server (Hashicorp Vault)               |
| Security                    | Intended for centralized user mamangement via IAM roles based cross-org auth approach (IAM roles per account to be assumed still needed. Also to centralize AWS CloudTrail and AWS Config logs, and used as the master AWS GuardDuty Account                                               |
| Legacy                      | Your pre existing AWS Accounts to be invited as members of the new AWS Organization, probably several services and workloads are going to be progressively migrated to your new Accounts.                                                                                                  |
| Apps DevStg                 | Host your DEV, QA and STG environment workloads Compute / Web App Servers (K8s Clusters and Lambda Functions), Load Balancers, DB Servers, Caching Services, Job queues & Servers, Data, Storage, CDN                                                                                      |
| Apps Prod                   | Host your PROD environment workloads Compute / Web App Servers (K8s Clusters and Lambda Functions), Load Balancers, DB Servers, Caching Services, Job queues & Servers, Data, Storage, CDN                                                                                                 |


## Read more

### Why you should use AWS Organizations? (https://aws.amazon.com/organizations/) 
- **Billing:** Consolidated billing for all your accounts within organization, enhanced per account cost 
filtering and RI usage (https://aws.amazon.com/about-aws/whats-new/2019/07/amazon-ec2-on-demand-capacity-reservations-shared-across-multiple-aws-accounts/)  
- **Security I:** Extra security layer: You get fully isolated infrastructure for different organizations 
units in your projects, eg: Dev, Prod, Shared Resources, Security, Users, BI, etc.
- **Security II:** Using AWS Organization you may use Service Control Policies (SCPs) to control which 
AWS services are available within different accounts.
- **Networking:** Connectivity and access will be securely setup via VPC peering + NACLS + Sec Groups
 everything with private endpoints only accessible vía Pritunl VPN significantly reducing the surface of attack.
- **User Mgmt:** You can manage all your IAM resources (users/groups/roles) and policies in one 
place (usually, security/users account) and use AssumeRole to works with org accounts.
- **Operations:** Will reduce the **blast radius** to the maximum possible.   
- **Compatibility:** Legacy accounts can be invited (https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_invites.html) as a
 member of the new Organization and afterwards even imported into your terraform code (https://www.terraform.io/docs/providers/aws/r/organizations_account.html#import).
- **Migration:** After having your baseline AWS Org reference cloud solutions architecture deployed (IAM, VPC, NACLS, VPC-Peering, DNS Cross-Org,
 CloudTrail, etc.) you're ready to start progressively orchestrating new resources in order to segregate different Environment and Services per account.
 This approach will allow you to start a **1 by 1 Blue/Green (Red/Black) migration without affecting any of your services at all**. You would like to take
 advantage of an Active-Active DNS switchover approach (nice as DR exercise too). 
    - **EXAMPLE:** Jenkins CI Server Migration steps:
      1. Let's say you have your EC2_A (`jenkins.aws.domain.com`) in Account_A (Legacy), so you could deploy a brand new EC2_B Jenkins Instance.
      in Account_B (Shared Resources).
      2. Temporally associated with `jenkins2.aws.domain.com`
      3. Sync it's current data (`/var/lib/jenkins`)
      4. Test and fully validate every job and pipeline works as expected.
      5. In case you haven't finished your validations we highly recommend to declare everything as code and fully automated 
      so as to destroy and re-create your under development env on demand to save costs.
      6. Finally switch `jenkins2.aws.domain.com` -> to -> `jenkins.aws.domain.com`
      7. Stop your old EC2_A.
      8. If everything looks fine after after 2/4 weeks you could terminate your EC2_A (hope everything is as code and just `terraform destroy`)
      9. Considering the previously detailed steps plan your roadmap to move forward with every other component to be migrated.

### AWS reference links
Consider the following AWS official links as reference:

- **AWS Multiple Account User Management Strategy:** https://docs.aws.amazon.com/IAM/latest/UserGuide/tutorial_cross-account-with-roles.html
- **AWS Muttiple Account Security Strategy** https://docs.aws.amazon.com/awscloudtrail/latest/userguide/cloudtrail-sharing-logs.html
- **AWS Multiple Account Billing Strategy:** https://aws.amazon.com/answers/account-management/aws-multi-account-billing-strategy/
- **AWS Secure Account Setup:** https://aws.amazon.com/answers/security/aws-secure-account-setup/
- **Authentication and Access Control for AWS Organizations:** 
https://docs.aws.amazon.com/organizations/latest/userguide/orgs_permissions.html (keep in mind EC2 and other services can also use AWS IAM Roles to get secure cross-account access)


## TODO

Develop a Terraform 0.12 compatible module: `terraform-aws-organizations` -> https://registry.terraform.io/modules/binbashar

---

# Release Management

## Docker based makefile commands

* <https://cloud.docker.com/u/binbash/repository/docker/binbash/git-release>
* <https://github.com/binbashar/bb-devops-tf-aws-organizations/blob/master/Makefile>

Root directory `Makefile` has the automated steps (to be integrated with **CircleCI jobs** []() )

### CircleCi PR auto-release job

<div align="left">
  <img src="https://raw.githubusercontent.com/binbashar/bb-devops-tf-aws-organizations/master/figures/circleci.png" alt="leverage-circleci" width="230"/>
</div>

- <https://circleci.com/gh/binbashar/bb-devops-tf-aws-organizations>
- **NOTE:** Will only run after merged PR.

### Manual execution from workstation

```
$ make
Available Commands:
 - release-major-with-changelog make changelog-major && git add && git commit && make release-major
 - release-minor-with-changelog make changelog-minor && git add && git commit && make release-minor
  - release-patch-with-changelog make changelog-patch && git add && git commit && make release-patch
