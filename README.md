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
+ dev/             (resources for dev account)
    ...
+ root-org/        (resources for the root-org account)
    ...
+ security/        (resources for the security + users account)
    ...
+ shared/          (resources for the shared account)
    ...
```

<div align="center">
  <img src="./%40figures/binbash-aws-organizations.png"
  alt="leverage" width="1000"/>
</div>

Under every account folder you will see a service layer structure similar to the following:
```
shared/
    1_tf-backend/
    2_secrets/
    3_identities/
    4_security/
    5_network/
    6_certificates/
    7_dns/
    8_common/
    ...
```

Such separation is meant to avoid situations in which a single folder contains a lot of resources. 
That is important to avoid because at some point, running `terraform plan or apply` stats taking too long and that 
becomes a problem.

This organization also provides a layout that is easier to navigate and discover. 
You simply start with the accounts at the top level and then you get to explore the resource categories within 
each account.

## Read more
Refer to the README.md file in each of the folders described above for details on how to work with each.

Also make sure you check out the [documentation](@docs/index.html) in the docs directory.

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
