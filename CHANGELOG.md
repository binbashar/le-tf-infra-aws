# Change Log

All notable changes to this project will be documented in this file.

<a name="unreleased"></a>
## [Unreleased]



<a name="v1.3.74"></a>
## [v1.3.74] - 2021-10-28

- updating .gitignore to avoid common.tfvars
- removing common.tfvars


<a name="v1.3.73"></a>
## [v1.3.73] - 2021-10-28

- Revert "Feature | build.env to tf 1.0.9 + configs updated to .tfvars  => leverage cli 1.1.0 + deactivate cf-s3-www.binbash.com.ar"
- fixing .gitignore from common.config to common.tfvars
- Renaming common.config.example to .tfvars.example removing common.tfvars
- adding missing vars to avoid warnings + adding new www.binbash.com.ar records
- IMPORTANT! Setting network/us-east-1/base-network => var enable_tgw = false by default
- renaming apps-prd/config/backend.config to backend.tfvars
- removing shared/us-east-1/base-network/build.env since it has been tested with tf 1.0.9 and everything works fine
- Fixing leverage cli organization version variable to terraform 1.0.9
- pointing cds-s3-frontend stack to its latets terraform version (tested and working fine)
- disabling and destroying old dev.binbash.com.ar and www.binbash.com.ar cloudfront + s3 stacks
- updating .gitignore to include every keys dir through wilcard expression
- renaming all configs as .tfvars
- Updating network account to have DR std dir structure


<a name="v1.3.72"></a>
## [v1.3.72] - 2021-10-27

- Create ElasticSearch/Kibana and Prometheus/Grafana in the Shared DR ([#319](https://github.com/binbashar/bb-devops-tf-infra-aws/issues/319))


<a name="v1.3.71"></a>
## [v1.3.71] - 2021-10-26

- Shared DR: VPC Peerings ([#318](https://github.com/binbashar/bb-devops-tf-infra-aws/issues/318))


<a name="v1.3.70"></a>
## [v1.3.70] - 2021-10-19

- Create SockShop DemoApp ECR repositories in both regions; also create DR VPC in Shared ([#316](https://github.com/binbashar/bb-devops-tf-infra-aws/issues/316))


<a name="v1.3.69"></a>
## [v1.3.69] - 2021-10-18

- Create EKS layers in the secondary region ([#315](https://github.com/binbashar/bb-devops-tf-infra-aws/issues/315))


<a name="v1.3.68"></a>
## [v1.3.68] - 2021-10-08

- Create FUNDING.yml


<a name="v1.3.67"></a>
## [v1.3.67] - 2021-10-07

- Refactor all accounts directories to add region subdirectories ([#314](https://github.com/binbashar/bb-devops-tf-infra-aws/issues/314))


<a name="v1.3.66"></a>
## [v1.3.66] - 2021-10-06

- Small sso org enabling change
- Merge branch 'master' into feature/open-soruce-repo
- sso + jumpcloud


<a name="v1.3.65"></a>
## [v1.3.65] - 2021-10-06

- Add more permissions to DevOps role in order try out more AWS services ([#312](https://github.com/binbashar/bb-devops-tf-infra-aws/issues/312))


<a name="v1.3.64"></a>
## [v1.3.64] - 2021-10-01

- Change tag refs to lowerCamelCase
- Change FirewallManager resource_tags to true
- Fix tfstate path
- Rename wrong filename
- Remove AWS config authorization resources
- Remove AWS config authorization resources
- Remove AWS config authorization resources
- Add AWS Config delegation to the Security account
- Add AWS Config delegation to the Security account
- Update resource_tags to use FirewallManager tag
- Add AWS Config agregator into the Security account


<a name="v1.3.63"></a>
## [v1.3.63] - 2021-09-30

- Add resource dependecies for FMS
- Change Network Firewall module version
- Update terraform-aws-firewall-manager module source to Binbash release
- * Update terraform-aws-firewall-manager module source to Binbash release * Update fms policies & rules
- Add DNS Firewall rules support in FMS
- Ad Network Firewall rules definitions
- Add Network Firewall Policies


<a name="v1.3.62"></a>
## [v1.3.62] - 2021-09-17

- Rename service policies
- Add SecOps role in the network account
- Update policies default values
- Remove not longer needed dependency
- Remove not longer needed dependency
- Remove root profile
- Add FMS account association from the root layer
- * Add Web ACL rules for CloudFromt * Remove FMS account assocition from the security layer
- Add policies for secops role
- Fix required_tags_resource_types typo
- Add default FMS account association logic & NFS staless default actions
- * Disable aggregate organization setting
- Fix assume role for secops
- * Set module source to binbash fork / branch * Add provider anmed aws.admin in fms module * Define fms account in module * Set orchestration config for nfw
- Fix SecOps aws_iam_policy resource name
- Add SecOps groups and cross-account access
- Fix SecOps aws_iam_policy resource name
- Add SecOps role
- Add SecOps role
- Add first implementation for Firewall Manager
- Set network security-compliance tftste file


<a name="v1.3.61"></a>
## [v1.3.61] - 2021-09-06

- removing legacy diagram files
- running make pre-commit to fix -> Trim Trailing Whitespaces check
- Adding code of conduct, updateing license and adding contributing guidelines


<a name="v1.3.60"></a>
## [v1.3.60] - 2021-09-02

- Remove aws backup role from SCP policy
- Add tag key condition fro creation/deletion of EC2, EKS and RDS tags
- Change tag key/value to make its purpose clearer
- Add delete_protection policy in all accounts
- Add tag protection policy (SCP) for DevOps roles
- Remove create tag denial
- Add tag protection policy (SCP)
- Add profile and region variable to RAM enabling command
- Add protection tag in locals
- Add delete proctecton policy (SCP)


<a name="v1.3.59"></a>
## [v1.3.59] - 2021-09-02

- Reduce number of subnets in Network and add a few more permissions to DevOps role in Shared ([#306](https://github.com/binbashar/bb-devops-tf-infra-aws/issues/306))


<a name="v1.3.58"></a>
## [v1.3.58] - 2021-09-01

- Fix undeclared variable warning ([#304](https://github.com/binbashar/bb-devops-tf-infra-aws/issues/304))


<a name="v1.3.57"></a>
## [v1.3.57] - 2021-08-31

- Update DevOps and DeployMaster permissions ([#303](https://github.com/binbashar/bb-devops-tf-infra-aws/issues/303))


<a name="v1.3.56"></a>
## [v1.3.56] - 2021-08-27

- Fix Shared VPC FlowLogs, add DevOps role permissions on Athena, and create a role for Grafana on the network account ([#302](https://github.com/binbashar/bb-devops-tf-infra-aws/issues/302))


<a name="v1.3.55"></a>
## [v1.3.55] - 2021-08-26

- Add README for the HOME_NET use case
- Add HOME_NET variable in stateful-group-1 rule
- Remove not longer used customer_gateways variable
- Move customer gateways definitions to a locals file
- Move customer gateways definitions to a locals file


<a name="v1.3.54"></a>
## [v1.3.54] - 2021-08-25

- Add deny domain access example for the AWS NFW
- Add a count for nfw module definition
- Change NFW implemteation to the module approach


<a name="v1.3.53"></a>
## [v1.3.53] - 2021-08-19

- Create a reference code for exporting RDS snapshots to S3 ([#299](https://github.com/binbashar/bb-devops-tf-infra-aws/issues/299))


<a name="v1.3.52"></a>
## [v1.3.52] - 2021-08-15

- Add grant network firewall to deploymaster role


<a name="v1.3.51"></a>
## [v1.3.51] - 2021-08-09

- Fix missing backend in RDS Aurora ([#297](https://github.com/binbashar/bb-devops-tf-infra-aws/issues/297))


<a name="v1.3.50"></a>
## [v1.3.50] - 2021-08-09

- Demoapps ([#296](https://github.com/binbashar/bb-devops-tf-infra-aws/issues/296))


<a name="v1.3.49"></a>
## [v1.3.49] - 2021-08-07

- Disable TGW by default
- Add enable_tgw in the common.config example file
- Fix wrong condition for TGW/Peerings toggle
- Pinterraform-aws-vpn-gateway module
- Fix wrong inspection route table id output value
- Add local_ipv4_network_cidr and remote_ipv4_network_cidr support
- Add TGW VPN route table associations
- Set single nat gateway for all AZs as default
- Add TGW VPN route table associationsç
- Add vpn_connection_static_routes_only parameter in auto.tfvars
- Fix Network Firewall endpoints issue when adding / removing subnets
- Fix Network Firewall endpoints issue when adding / removing subnets
- Separate logic for network-base and TGW layers


<a name="v1.3.48"></a>
## [v1.3.48] - 2021-08-03

- Merge branch 'feature/tgw-vpn-attachments' of github.com:binbashar/le-tf-infra-aws into feature/tgw-vpn-attachments
- Add all VPN Gateway parameters supported by the module
- Add comments for TGW routes in the vpc attachacmemts
- Support 1 or more rule creation based in the amount of CIDR blocks
- Add vpn gateways support
- Add all VPN Gateway parameters supported by the module
- Add comments for TGW routes in the vpc attachacmemts
- Support 1 or more rule creation based in the amount of CIDR blocks
- Add vpn gateways support


<a name="v1.3.47"></a>
## [v1.3.47] - 2021-07-30

- Fix duplicated variable: 'network_account_id' ([#294](https://github.com/binbashar/bb-devops-tf-infra-aws/issues/294))


<a name="v1.3.46"></a>
## [v1.3.46] - 2021-07-30

- [#154](https://github.com/binbashar/bb-devops-tf-infra-aws/issues/154) | very small circleci sintaxt enhancement


<a name="v1.3.45"></a>
## [v1.3.45] - 2021-07-30

- [#154](https://github.com/binbashar/bb-devops-tf-infra-aws/issues/154) | updating vm in release job
- [#154](https://github.com/binbashar/bb-devops-tf-infra-aws/issues/154) | adding some pre-commit debugging commands
- [#154](https://github.com/binbashar/bb-devops-tf-infra-aws/issues/154) | adding some pre-commit debugging commands
- [#154](https://github.com/binbashar/bb-devops-tf-infra-aws/issues/154) | adding some pre-commit debugging commands
- [#154](https://github.com/binbashar/bb-devops-tf-infra-aws/issues/154) | adding some pre-commit debugging commands
- [#154](https://github.com/binbashar/bb-devops-tf-infra-aws/issues/154) | adding some pre-commit debugging commands
- [#154](https://github.com/binbashar/bb-devops-tf-infra-aws/issues/154) | adding some pre-commit debugging commands
- [#154](https://github.com/binbashar/bb-devops-tf-infra-aws/issues/154) | adding some pre-commit debugging commands
- [#154](https://github.com/binbashar/bb-devops-tf-infra-aws/issues/154) | adding some pre-commit debugging commands


<a name="v1.3.44"></a>
## [v1.3.44] - 2021-07-29

- [#154](https://github.com/binbashar/bb-devops-tf-infra-aws/issues/154) | using pip3 in ci pipeline
- [#154](https://github.com/binbashar/bb-devops-tf-infra-aws/issues/154) | using pip3 in ci pipeline
- [#154](https://github.com/binbashar/bb-devops-tf-infra-aws/issues/154) | using pip3 in ci pipeline
- [#154](https://github.com/binbashar/bb-devops-tf-infra-aws/issues/154) | adding ci step to register HashiCorp GPG keys
- [#154](https://github.com/binbashar/bb-devops-tf-infra-aws/issues/154) | upgrading circleci ubuntu vm version
- [#154](https://github.com/binbashar/bb-devops-tf-infra-aws/issues/154) | upgrading circleci ubuntu vm version
- [#154](https://github.com/binbashar/bb-devops-tf-infra-aws/issues/154) | merging latest master code and fixing conflicts
- [#154](https://github.com/binbashar/bb-devops-tf-infra-aws/issues/154) | config/common.config.example updated including new supported network account
- [#154](https://github.com/binbashar/bb-devops-tf-infra-aws/issues/154) | security/security-monitoring-* layers integrated with vault hcp
- [#154](https://github.com/binbashar/bb-devops-tf-infra-aws/issues/154) | shared/base-identities removing not necessary user
- [#154](https://github.com/binbashar/bb-devops-tf-infra-aws/issues/154) | integrating cross account notification layers with vault hcp
- [#154](https://github.com/binbashar/bb-devops-tf-infra-aws/issues/154) | integrating apps-devstg/databases-* layers with vault hcp
- [#154](https://github.com/binbashar/bb-devops-tf-infra-aws/issues/154) | adding network_account_id variable cross account layers
- [#154](https://github.com/binbashar/bb-devops-tf-infra-aws/issues/154) | integrating apps-devstg/databases layers with vault


<a name="v1.3.43"></a>
## [v1.3.43] - 2021-07-22

- Remove debuggin code
- Remove extra lines
- Add private subnet cidr in NACLs rules
- * Add enable_network_firewall variable * Add prefix to resource names
- Update  deny example using AWS Network Firewall DomainList
- Fix TGW route table associations for NETFW
- Add deny example using AWS Network Firewall DomainList
- Add route table association toggle
- * Move inspection-vpc into network-firewall layer * Move Network firewall RT login to TGW layer
- Add default routes for inspection and nework firewall route tables
- Move inspection vpc definition to inspection-network
- Move inspection vpc definition to base-network
- Add toggle condition for network attachments
- Add implementation fro the inspection TGW route table
- Fix tgw_vpc_attachments_and_subnet_routes indices ref
- Add disable variable in tfvars
- * Add dynamic RT assignation based on enable_network_firewall var * Add disable variable to prevent some resources to be deploy (for debuggig)
- Add toggle for TGW / VPC peering per VPCs level
- Add TGW / VPC Peering per VPCwq
- Fix dynamic vpc attachments
- Add toggle in TGW route table association to support AWS Firewall network
- Add enable_network_firewall for tfvars and ouputs
- Change to for_each iteration for modules
- Add treatement for inspection network VPC & TGW
- Add treatement for the default route in the network VPC
- Add network inspection & RT togglin per VPC attachment
- Add network-firewall layer
- Grant access to Devops for AW Firewall Manager and AWS Network Firewall


<a name="v1.3.42"></a>
## [v1.3.42] - 2021-07-17

- Add missing permissions to sockshop demoapp user ([#287](https://github.com/binbashar/bb-devops-tf-infra-aws/issues/287))


<a name="v1.3.41"></a>
## [v1.3.41] - 2021-07-16

- Update Aurora layer to also create MySQL resources for Sock-Shop DemoApp ([#286](https://github.com/binbashar/bb-devops-tf-infra-aws/issues/286))


<a name="v1.3.40"></a>
## [v1.3.40] - 2021-07-14

- Fix NACL and public subnets range
- Fix NACL in shared/base-network
- Fix NACL in apps-devstg/k8s-eks/network$
- Fix NACL in apps-prd/k8s-eks/network
- Fix NACL in apps-prd/base-network


<a name="v1.3.39"></a>
## [v1.3.39] - 2021-07-13

- Downgrade all EKS DemoApps layers to Terraform v0.14.4 ([#284](https://github.com/binbashar/bb-devops-tf-infra-aws/issues/284))


<a name="v1.3.38"></a>
## [v1.3.38] - 2021-07-13

- Update DemoApps layers to Terraform v.0.15.5 ([#283](https://github.com/binbashar/bb-devops-tf-infra-aws/issues/283))


<a name="v1.3.37"></a>
## [v1.3.37] - 2021-07-13

- Modify PRD private subnet CIDR to define a single entry that encompas… ([#281](https://github.com/binbashar/bb-devops-tf-infra-aws/issues/281))


<a name="v1.3.36"></a>
## [v1.3.36] - 2021-07-13

- Fix dynamic role creation for iam-assumable-role-with-oidc
- Add support access to devops


<a name="v1.3.35"></a>
## [v1.3.35] - 2021-07-13

- Add support permissions to DevOps role in Shared ([#279](https://github.com/binbashar/bb-devops-tf-infra-aws/issues/279))


<a name="v1.3.34"></a>
## [v1.3.34] - 2021-07-09

- * Fix typo in transit_gateway.tf * Add comment to use network.auto.tfvars


<a name="v1.3.33"></a>
## [v1.3.33] - 2021-07-09

- Remove build.env files
- Add shared/k8s-eks-prd layer
- Add TGW / VPC Peering toggle to apps-prd
- Add TGW & VPC Peering toggle for apps-devstg/k8s-eks/network
- Add Togggle between TGW & VPC Peering
- Add vpc-apps-prd-eks in VPCs
- Update vpc shared variable name
- Add Enable resource sharing with AWS Organizations
- Update README for Transit Gateway & RAM enabling
- Add apps-prd layer
- Add prd rout into shared public route table
- Add shared vpc attachments
- Add apps-prd/k8s-eks layer
- Update apps-prd/network layerCC
- Update network public RT logic
- Add apps-prd/k8s-eks/network layer
- Add apps-prd/k8s-eks/network layer
- Add TGW enabled output
- Move Transit Gateway to base-network
- Add NACL definition
- Update TGW README
- Update VPC and VPC endpoints modules
- Remove unnecesary comment
- Remove unused IAM users
- Update tgw.tfvars
- Remove unused static route definition
- Add VPC CIDRs to networ public RT
- Add Name tag to VPC attachments
- Fix typos in README
- Implement single internet exit point from multiple VPCs using TGW
- Add network account to TGW
- Add implementation using the CloudPosse module
- Add TGG implementation using the CloudPosse module
- Enable trusted access with AWS RAM in the Organization
- Add VPC network datasource to the TGW
- Add base-network to network account
- Add vpc definition for networks account
- Update vpcs references
- Add code for TGW
- Add permission to assume roles for Devops, Auditor, FinOps, etc
- Fix roles & groups in network/base-identities layer
- Add remote bucket backend for network account
- Fix typo in network layer
- Disable remote state for network account
- Add network account definitions


<a name="v1.3.32"></a>
## [v1.3.32] - 2021-06-29

- Update Github Runners' EC2 userdata script to match the installed module version ([#275](https://github.com/binbashar/bb-devops-tf-infra-aws/issues/275))


<a name="v1.3.31"></a>
## [v1.3.31] - 2021-06-25

- Fix peerings with HCP Vault ([#273](https://github.com/binbashar/bb-devops-tf-infra-aws/issues/273))


<a name="v1.3.30"></a>
## [v1.3.30] - 2021-06-24

- shared/tools-github-selfhosted-runners renaming layer with - and migrating secrets to vault
- shared/base-network peering id updated
- shared/notifications secrets migrated to vault
- apps-devstg/databases removing secrets.enc favouring vault source secret
- Add another MFA script that supports using aws-vault and remove build… ([#271](https://github.com/binbashar/bb-devops-tf-infra-aws/issues/271))


<a name="v1.3.29"></a>
## [v1.3.29] - 2021-06-18

- shared account: disabling storage/backup-gdrive layer
- shared account: renaming storage layer adding a sub-layer for better segregation of future storage resources
- shared account: removing deprecated Makefiles
- security account: removing deprecated Makefiles
- root account: removing deprecated Makefiles
- apps-prd account: removing deprecated Makefiles
- apps-devstg account: removing deprecated Makefiles
- bug/[#253](https://github.com/binbashar/bb-devops-tf-infra-aws/issues/253) | updating circleci pipeline to use tf-0.14 + removing backup job


<a name="v1.3.28"></a>
## [v1.3.28] - 2021-06-17

- Upgrade root/organizations to TF 0.14.11
- Upgrade root/organizations to TF 0.14.11
- Upgrade root/organizations TF 0.14.11
- Upgrade root/security-monitoring-dr to TF 0.14.11
- Upgrade root/security-monitoring to TF 0.14.11
- Upgrade root/security-keys to TF 0.14.11
- Upgrade root/security-base to TF 0.14.11
- Upgrade root/security-compliance to TF 0.14.11
- Upgrade root/security-audit to TF 0.14.11
- Upgrade root/organizations to TF 0.14.11
- Upgrade root/notifications to TF 0.14.11
- Upgrade root/cost-mgmt to TF 0.14.11
- Upgrade base-tf-backend to TF 0.14.11
- Upgrade root/backups to TF 0.14.11


<a name="v1.3.27"></a>
## [v1.3.27] - 2021-06-17

- Add vpc endpoints for k8s-eks-demoapps


<a name="v1.3.26"></a>
## [v1.3.26] - 2021-06-16

- Change Terraform module sources to point to binbash repos
- Upgrade apps-devstg/k8s-eks-demoapps TF 0.14.11
- Upgrade apps-devstg/tools-cloud-nuke TF 0.14.11
- Upgrade /apps-devstg/storage TF 0.14.11
- Upgrade apps-devstg/security-keys-dr TF 0.14.11
- Upgrade apps-devstg/security-keys TF 0.14.11
- Upgrade apps-devstg/security-firewall TF 0.14.11
- Upgrade apps-devstg/security-compliance TF 0.14.11
- Upgrade apps-devstg/security-certs TF 0.14.11
- Upgrade apps-devstg/security-base  TF 0.14.11
- Upgrade apps-devstg/security-audit TF 0.14.11
- Upgrade apps-devstg/notifications  TF 0.14.11
- Upgrade apps-devstg/k8s-kind/k8s-resources TF 0.14.11
- Upgrade apps-devstg/ec2-fleet-ansible to TF 0.14.11
- Upgrade apps-devstg/databases-pgsql to TF 0.14.11
- Upgrade apps-devstg/databases-mysql to TF 0.14.11
- Upgrade apps-devstg/base-identities to TF 0.14.11
- Upgrade apps-devstg/base-tf-backend to TF 0.14.11
- Upgrade apps-devstg/k8s-eks/network to TF 0.14.11
- Upgrade apps-devstg/base-identities to TF 0.14.11
- Upgrade apps-devstg/base-identities to TF 0.14.11
- Upgrade apps-devstg/base-identities to TF 0.14.11
- Upgrade apps-devstg/k8s-eks/k8s-resources to TF 0.14.11
- Upgrade apps-devstg/k8s-eks/clusters to TF 0.14.11
- Upgrade apps-devstg/k8s-eks/network to TF 0.14.11
- Upgrade apps-devstg/k8s-eks/network to TF 0.14.11
- Upgrade apps-devstg/base-certificates to TF 0.14.11
- Upgrade apps-devstg/backups to TF 0.14.11


<a name="v1.3.25"></a>
## [v1.3.25] - 2021-06-15

- BBL-192 | Upgrading root/base-identities to tf-0.14.11 + adding new user to root account


<a name="v1.3.24"></a>
## [v1.3.24] - 2021-06-15

- Add HPA and Cluster Autoscaler to DemoApps ([#265](https://github.com/binbashar/bb-devops-tf-infra-aws/issues/265))


<a name="v1.3.23"></a>
## [v1.3.23] - 2021-06-14

- Upgrade security/security-monitoring-dr to TF 0.14.11
- Upgrade security/security-monitoring to TF 0.14.11
- Upgrade security/security-keys to TF 0.14.11
- Upgrade security/security-compliance to TF 0.14.11
- Upgrade security/security-base to TF 0.14.11
- Upgrade security/security-audit to TF 0.14.11
- Fix metric name suffix in app-prd
- Fix metric name suffix in shared
- Fix alarm name suffix in app-prd
- Upgrade security/base-identities to TF 0.14.11


<a name="v1.3.22"></a>
## [v1.3.22] - 2021-06-13

- Revert Terraform version as it makes other layers fail ([#263](https://github.com/binbashar/bb-devops-tf-infra-aws/issues/263))


<a name="v1.3.21"></a>
## [v1.3.21] - 2021-06-13

- Fix Terraform version ([#262](https://github.com/binbashar/bb-devops-tf-infra-aws/issues/262))


<a name="v1.3.20"></a>
## [v1.3.20] - 2021-06-10

- Upgrade shared/tools-vpn-server and shared/tools-vault layers to TF 0.14.11
- Upgrade shared/tools-vault to TF 0.14.11
- Upgrade shared/tools-prometheus to TF 0.14.11
- Upgrade shared/tools-managedeskibana to TF 0.14.11
- Upgrade shared/tools-jenkins to TF 0.14.11
- Upgrade shared/tools-github_selfhosted_runners to TF 0.14.11
- Upgrade shared/tools-eskibana to TF 0.14.11
- Upgrade shared/tools-cloud-scheduler-stop-start to TF 0.14.11
- Upgrade shared/tools-cloud-scheduler-stop-start to TF 0.14.11
- Upgrade shared/storage to TF 0.14.11
- Upgrade shared/security-keys-dr to TF 0.14.11
- Upgrade shared/security-compliance to TF 0.14.11
- Upgrade shared/security-base to TF 0.14.11
- Upgrade shared/security-audit to TF 0.14.11
- Upgrade shared/k8s-eks-demoapps/identities layer to TF 0.14.11
- Upgrade shared/k8s-eks/identities layer to TF 0.14.11
- * Upgrade shared/container-registry layer to TF 0.14.11 * Upgrade shared/ec2-fleet layer to TF 0.14.11
- * Upgrade shared/base-dns to TF 0.14.11 * Add eks-demoapps VPC to Route 53 private zone
- Upgrade shared/backups to TF 0.14.11
- Upgrade shared/base-f-backend to TF 0.14.11
- Upgrade shared/base-identities to TF 0.14.11


<a name="v1.3.19"></a>
## [v1.3.19] - 2021-06-06

- Add build.env to security-certs
- Update AuthorizationFailureCount alarm threshold
- Add AWS icon to slack notifications in lambda env variables
- Update Slack channels names
- Add implementation to avoid duplicated Route53 records for alternative domains in ACM
- * Ugrade app-prd/security-base to TF 0.14.11 * Bump version for terraform-aws-root-login-notifications module
- * Add alarm_suffix variable * Add security-sec sns topic * Fix cloud_watch_logs_group_arn attribute
- Update metrics object generation
- Remove alarm_sufix variable
- Fix typo in  metrics definitinions variable
- Add metrics definitinions variable
- Change CloudWatch metrics definitions according to lastet module versions
- * Ugrade app-prd/backups layer to TF 0.14.11 * Change to terraform-aws-backup module
- * Ugrade app-prd/security-compliance layer to TF 0.14.11 * Bump versions for terraform-aws-logs and terraform-config modules
- * Ugrade app-prd/ec2-fleet layer to TF 0.14.11 * Bump versions for terraform-aws-security-group and terraform-aws-instance modules
- Ugrade app-prd/security-cert to TF 0.14.11
- * Ugrade app-prd/security-keys to TF 0.14.11 * Bump versions for terraform-aws-kms-key module
- * Ugrade app-prd/security-audit to TF 0.14.11 * Bump versions for terraform-aws-cloudtrail and terraform-aws-cloudtrail-cloudwatch-alarms.
- Ugrade app-prd/cdn-s3-frontend to TF 0.14.11
- * Ugrade app-prd/cdn-s3-frontend to TF 14 *  Bump versions for terraform-aws-cloudfront-s3-cdn nodule
- Ugrade app-prd/security-audit layer to TF 14
- * Ugrade app-prd/notification layer to TF 14 * Bump versions for terraform-aws-notify-slack module
- Ugrade app-prd/cdn-s3-frontend to TF 14
- Merge branch 'feature/tf-14' of github.com:binbashar/le-tf-infra-aws into feature/tf-14
- Ugrade app-prd/base-tf-backend to TF 14
- * Ugrade app-prd/base-identities to TF 14 * Bump module versions for aws-iam (user, group, role) role
- * Upgrade app-prd/base-network to TF 14 * Bump module versions for vpc, vpc-flowlog, natgw-notifications modules * Add KMS VPC Endpoint support * Removed commented old data source definitio code
- * Ugrade app-prd/base-identities to TF 14 * Bump module versions for aws-iam (user, group, role) role
- * Upgrade app-prd/base-network to TF 14 * Bump module versions for vpc, vpc-flowlog, natgw-notifications modules * Add KMS VPC Endpoint support * Removed commented old data source definitio code


<a name="v1.3.18"></a>
## [v1.3.18] - 2021-06-01

- Feature | Demoapps + RDS, Vault and ArgoCD integration ([#251](https://github.com/binbashar/bb-devops-tf-infra-aws/issues/251))


<a name="v1.3.17"></a>
## [v1.3.17] - 2021-05-31

- Add data source reimplementation using for_each


<a name="v1.3.16"></a>
## [v1.3.16] - 2021-05-29

- Add profile detection from locals.tf (backward compatible)
- Add VPC data source definitions to locals
- * Update Terraform min vertion to 0.14.11 * Update VPC module version to the lastest stable version * Add variables to the vpc module's inputs


<a name="v1.3.15"></a>
## [v1.3.15] - 2021-05-28

- Add permissions to DeployMaster role on EKS DemoApps ([#248](https://github.com/binbashar/bb-devops-tf-infra-aws/issues/248))


<a name="v1.3.14"></a>
## [v1.3.14] - 2021-05-27

- Update leverage output so it supports passing arguments ([#247](https://github.com/binbashar/bb-devops-tf-infra-aws/issues/247))


<a name="v1.3.13"></a>
## [v1.3.13] - 2021-05-27

- Add unzip to GH runners ([#246](https://github.com/binbashar/bb-devops-tf-infra-aws/issues/246))


<a name="v1.3.12"></a>
## [v1.3.12] - 2021-05-27

- Make sure GH Runners' encrypted secrets match the actual ones, update runners user-data to enable passwordless sudo, and push to the repo zip files that are needed to deploy the runners ([#245](https://github.com/binbashar/bb-devops-tf-infra-aws/issues/245))


<a name="v1.3.11"></a>
## [v1.3.11] - 2021-05-26

- Add CA certificate to EKS DemoApps outputs ([#244](https://github.com/binbashar/bb-devops-tf-infra-aws/issues/244))


<a name="v1.3.10"></a>
## [v1.3.10] - 2021-05-26

- Add flags to enable DemoApps ([#241](https://github.com/binbashar/bb-devops-tf-infra-aws/issues/241))


<a name="v1.3.9"></a>
## [v1.3.9] - 2021-05-25

- Create peering between EKS DemoApps and HCP ([#240](https://github.com/binbashar/bb-devops-tf-infra-aws/issues/240))


<a name="v1.3.8"></a>
## [v1.3.8] - 2021-05-22

- Remove empty lines
- Add minimum background overview regarding Velero in README
- Add TODOs into the README
- Add account & region data sources
- Add backup documentation
- Fix typo in resource name
- Add velelro implementation
- Add Velero implementetion for k8s-eks


<a name="v1.3.7"></a>
## [v1.3.7] - 2021-05-18

- Remove network.auto.tfvars from the repo so they do not override custom values defined in terraform.tfvars file used by workflows ([#236](https://github.com/binbashar/bb-devops-tf-infra-aws/issues/236))


<a name="v1.3.6"></a>
## [v1.3.6] - 2021-05-17

- Update Grafana instance profile permissions and create Grafana roles … ([#235](https://github.com/binbashar/bb-devops-tf-infra-aws/issues/235))


<a name="v1.3.5"></a>
## [v1.3.5] - 2021-05-14

- Add working example of FluentD talking to AWS ES with auth enabled... ([#234](https://github.com/binbashar/bb-devops-tf-infra-aws/issues/234))


<a name="v1.3.4"></a>
## [v1.3.4] - 2021-05-13

- Add external-dns role & policies for k8s-eks
- Add logic to enanle IMC endpoints using variables
- * Remove terraform version constraint * CHange role used for public extenral-dns
- Merge branch 'feature/k8s-eks-imc' of github.com:binbashar/le-tf-infra-aws into feature/k8s-eks-imc
- Copy demoapps.tf
- Copy demoapps.tf
- Replicate demoapss files in k8-eks layer
- Replicate k8s-eks-demoapps in k8s-eks


<a name="v1.3.3"></a>
## [v1.3.3] - 2021-05-11

- Merge branch 'master' into feature/eks-imc
- Add IMC endpoint conditional for emojivoto
- Add demoapss changes into Kind layer
- Add placeholder for UptimeRObot apkey and Aaertcontacts
- Set default values via tfvars
- Set K8s Dashboard as private
- Add Kubernates Dashboard chart parameterization
- Add network variables for each account
- Fix variable names
- Enable private ingresses & dns sync
- Add external-dns-public role & policy
- Add variables to the VPC module
- Add k8s dashboard public endpoint
- Add missing namespace variable in chart template
- Update apky for Ingress Monitor Controller
- Add Ingress Monitor Controller to k8s-eks-demoapps layer


<a name="v1.3.2"></a>
## [v1.3.2] - 2021-05-11

- Add a small Terraform State helper to Leverage build file ([#232](https://github.com/binbashar/bb-devops-tf-infra-aws/issues/232))


<a name="v1.3.1"></a>
## [v1.3.1] - 2021-05-07

- Add vault vars to shared/base-network ([#228](https://github.com/binbashar/bb-devops-tf-infra-aws/issues/228))


<a name="v1.2.31"></a>
## [v1.2.31] - 2021-05-06



<a name="v1.3.0"></a>
## [v1.3.0] - 2021-05-06

- Add fluentd to k8s-kind layer and update demoapps layer to enable flu… ([#221](https://github.com/binbashar/bb-devops-tf-infra-aws/issues/221))


<a name="v1.2.30"></a>
## [v1.2.30] - 2021-05-03

- Fix chart repo url
- Add IMC ingress endpoint for Kubernetes Dashboard


<a name="v1.2.29"></a>
## [v1.2.29] - 2021-04-30

- Add FluentD to EKS DemoApps stack and other small changes to ElasticS… ([#219](https://github.com/binbashar/bb-devops-tf-infra-aws/issues/219))


<a name="v1.2.28"></a>
## [v1.2.28] - 2021-04-30

- Chage ingress-monitor-controller-endpoint example
- Add example values for ingressmonitorcontroller chart
- Add ingressmonitorcontroller chart
- Add Ingress Monitor Controller chart installation
- Fix metallb enabled var


<a name="v1.2.27"></a>
## [v1.2.27] - 2021-04-30

- BBL-192 | updating README.md with new leverage cli approach
- BBL-192 | shared/tools-managedeskibana referencing to the Binbash Leverage forked module by convention


<a name="v1.2.26"></a>
## [v1.2.26] - 2021-04-28

- Update self-hosted ElasticSearch/Kibana layer... ([#215](https://github.com/binbashar/bb-devops-tf-infra-aws/issues/215))


<a name="v1.2.25"></a>
## [v1.2.25] - 2021-04-22

- Fix trailing whitespaces in chart yaml files
- Fix trailing whitespaces
- Add Metallb for for providing local LB to Kind


<a name="v1.2.24"></a>
## [v1.2.24] - 2021-04-22

- Goldilocks full demo ([#213](https://github.com/binbashar/bb-devops-tf-infra-aws/issues/213))


<a name="v1.2.23"></a>
## [v1.2.23] - 2021-04-21

- Force TF13 in EKS DemoApps k8s-resources ([#211](https://github.com/binbashar/bb-devops-tf-infra-aws/issues/211))


<a name="v1.2.22"></a>
## [v1.2.22] - 2021-04-21

- Add Goldilocks to EKS DemoApps layer ([#210](https://github.com/binbashar/bb-devops-tf-infra-aws/issues/210))


<a name="v1.2.21"></a>
## [v1.2.21] - 2021-04-21

- Implement Goldilocks ([#209](https://github.com/binbashar/bb-devops-tf-infra-aws/issues/209))


<a name="v1.2.20"></a>
## [v1.2.20] - 2021-04-19

- Create EKS layer for DemoApps and its required layers ([#208](https://github.com/binbashar/bb-devops-tf-infra-aws/issues/208))


<a name="v1.2.19"></a>
## [v1.2.19] - 2021-04-14

- Move back aws-iam-authenticator to the cluster layer and update k8s-resources layer with draft resources ([#207](https://github.com/binbashar/bb-devops-tf-infra-aws/issues/207))


<a name="v1.2.18"></a>
## [v1.2.18] - 2021-04-13

- Create infrastructure for Prometheus ([#206](https://github.com/binbashar/bb-devops-tf-infra-aws/issues/206))


<a name="v1.2.17"></a>
## [v1.2.17] - 2021-04-11

- Enable kubeconfig as an output of the EKS layer ([#205](https://github.com/binbashar/bb-devops-tf-infra-aws/issues/205))


<a name="v1.2.16"></a>
## [v1.2.16] - 2021-04-11

- Make sure we don't have aws auth managed by eks module ([#204](https://github.com/binbashar/bb-devops-tf-infra-aws/issues/204))


<a name="v1.2.15"></a>
## [v1.2.15] - 2021-04-10

- Disable managing of AWS Auth in EKS cluster layer to favor the managi… ([#203](https://github.com/binbashar/bb-devops-tf-infra-aws/issues/203))


<a name="v1.2.14"></a>
## [v1.2.14] - 2021-04-10

- Move EKS identities to a separate layer to simplify create/destroy op… ([#202](https://github.com/binbashar/bb-devops-tf-infra-aws/issues/202))


<a name="v1.2.13"></a>
## [v1.2.13] - 2021-04-09

- BBL-478-479 | adding vars to avoid tf warnings


<a name="v1.2.12"></a>
## [v1.2.12] - 2021-04-08

- BBL-478-479 | Adding new collaborator users to aws security account withing DevOps group (DevOps role assumable cross-org)


<a name="v1.2.11"></a>
## [v1.2.11] - 2021-04-06

- Update self-hosted github runners readme with further setup instructions and update secrets file ([#199](https://github.com/binbashar/bb-devops-tf-infra-aws/issues/199))


<a name="v1.2.10"></a>
## [v1.2.10] - 2021-04-06

- Create self-hosted Github Runners ([#198](https://github.com/binbashar/bb-devops-tf-infra-aws/issues/198))


<a name="v1.2.9"></a>
## [v1.2.9] - 2021-04-05

- Create user for Github Actions workflows ([#197](https://github.com/binbashar/bb-devops-tf-infra-aws/issues/197))


<a name="v1.2.8"></a>
## [v1.2.8] - 2021-03-26

- Update Jenkins and EKS to allow running Terraform commands from Jenkins via Leverage CLI ([#196](https://github.com/binbashar/bb-devops-tf-infra-aws/issues/196))


<a name="v1.2.7"></a>
## [v1.2.7] - 2021-03-25

- Add support for using a TTY when running Leverage CLI ([#195](https://github.com/binbashar/bb-devops-tf-infra-aws/issues/195))


<a name="v1.2.6"></a>
## [v1.2.6] - 2021-03-25

- Fix an issue with MFA config not properly honored in build.env ([#194](https://github.com/binbashar/bb-devops-tf-infra-aws/issues/194))


<a name="v1.2.5"></a>
## [v1.2.5] - 2021-03-22

- Add support for SELinux ([#193](https://github.com/binbashar/bb-devops-tf-infra-aws/issues/193))


<a name="v1.2.4"></a>
## [v1.2.4] - 2021-03-16

- Replicate small refactors made while working on helm and ansible repositories ([#192](https://github.com/binbashar/bb-devops-tf-infra-aws/issues/192))


<a name="v1.2.3"></a>
## [v1.2.3] - 2021-03-12

- Create RDS Aurora ([#191](https://github.com/binbashar/bb-devops-tf-infra-aws/issues/191))


<a name="v1.2.2"></a>
## [v1.2.2] - 2021-03-05

- BBL-24 | fixing inline comment at common.config.example
- BBL-24 | apps-devstg/database-mysql state fixed
- BBL-24 | ignoring commong.config since it has account ids
- BBL-24 | removing common.config and adding common.config.example preparing repo for open-source ver
- BBL-24 | shared layers to tf-0.14
- BBL-24 | apps-devstg layer to tf-0.14 + secrets from hashicorp vault


<a name="v1.2.1"></a>
## [v1.2.1] - 2021-03-04

- Create Vault infrastructure resources ([#190](https://github.com/binbashar/bb-devops-tf-infra-aws/issues/190))


<a name="v1.1.45"></a>
## [v1.1.45] - 2021-02-26



<a name="v1.2.0"></a>
## [v1.2.0] - 2021-02-26

- Add WAF v2 and ACM certificate for EKS ALB ([#188](https://github.com/binbashar/bb-devops-tf-infra-aws/issues/188))


<a name="v1.1.44"></a>
## [v1.1.44] - 2021-02-24

- Update build script to restrict which tasks can be run from root or account paths ([#187](https://github.com/binbashar/bb-devops-tf-infra-aws/issues/187))


<a name="v1.1.43"></a>
## [v1.1.43] - 2021-02-23

- BBL-468 | applying leverage tf-format to every layer
- Merge branch 'master' into fix/BBL-468-vpc-error
- BBL-468 | pointing makefile-lib ver to the latest stable version
- BBL-468 | upgrading base-network vpc module version to its latest stable ver + adding build.py per layer to enforce tf-0.14 to be used


<a name="v1.1.42"></a>
## [v1.1.42] - 2021-02-16

- AWS Backups ([#184](https://github.com/binbashar/bb-devops-tf-infra-aws/issues/184))


<a name="v1.1.41"></a>
## [v1.1.41] - 2021-02-08

- Leverage CLI build file and terraform module ([#182](https://github.com/binbashar/bb-devops-tf-infra-aws/issues/182))


<a name="v1.1.40"></a>
## [v1.1.40] - 2021-01-31

- Refactor EKS node group defaults, create identity provider for EKS, a… ([#181](https://github.com/binbashar/bb-devops-tf-infra-aws/issues/181))


<a name="v1.1.39"></a>
## [v1.1.39] - 2021-01-28

- Create user for cert-manager, use TF 13 with EKS layer, set sample DN… ([#180](https://github.com/binbashar/bb-devops-tf-infra-aws/issues/180))


<a name="v1.1.38"></a>
## [v1.1.38] - 2021-01-26

- BBL-192 | root/organizations adding guarduty service principal to org + tf-0.14 adjustments
- BBL-192 | apps-devstg/security-firewall WAF layer added to ref architecture
- Merge branch 'master' of github.com:binbashar/le-tf-infra-aws
- BBL-24 | root/organization aws_service_access_principals "access-analyzer.amazonaws.com" added


<a name="v1.1.37"></a>
## [v1.1.37] - 2021-01-21

- BBL-24 | root/organization adding aws_service_access_principals -> "access-analyzer.amazonaws.com"
- BBL-24 | updating shared/base-network NACLs protocol sintaxt for better understanding
- BBL-24 | apps-prd/base-network migrated to tf-0.14 + latest tf-vpc module ver + NACLs port fixed
- BBL-24 | apps-devstg/base-network migrated to tf-0.14 + latest tf-vpc module ver + NACLs port fixed
- BBL-24 | updating root-context Makefile to use latest makefiles-lib ver


<a name="v1.1.36"></a>
## [v1.1.36] - 2021-01-21

- Merge branch 'master' into feature/BBL-24-vault-vpc-peering-update
- BBL-24 | apps-devstg/k8s-eks/network locals.tf NACLs updated and applied
- BBL-24 | apps-devstg/base-network vpc peering file name updated with requester on its name for easier understanding
- BBL-24 | apps-devstg/k8s-eks/network upgrading to tf-0.14 + vpc peering with hashicorp Vault Cloud hvn
- BBL-24 | apps-devstg/k8s-eks/network vpc peering file name updated with requester on its name for easier understanding
- BBL-24 | apps-prd/base-network vpc peering file name updated with requester on its name for easier understanding
- BBL-24 | shared/base-network updated to tf-0.14 + latest tf vpc module + hashicorp vault cloud hvn vpc peering updated and tested
- BBL-24 | removing shared/base-network-integrations layer since we can't route traffic from other vpcs in the org (consider AWS TGW for this scenario)
- BBL-24 | renaming shared/base-network peering conecctions with accepter or requester on its file name for easier understanding
- BBL-24 | renaming not implemented shared/infra-prometheus layer with the '--' sufix to reflect it's not currently orchestrated
- Merge branch 'master' into feature/BBL-24-vault-vpc-peering-update
- BBL-24 | adding shared/base-network-integrations layer for vault cloud vpc peering
- BBL-24 | updating .gitigore with plan.save filename
- BBL-24 | updating makesfile-lib version


<a name="v1.1.35"></a>
## [v1.1.35] - 2021-01-21

- EKS updates ([#177](https://github.com/binbashar/bb-devops-tf-infra-aws/issues/177))


<a name="v1.1.34"></a>
## [v1.1.34] - 2021-01-19

- Rename EKS 'vpc' layer as 'network' and fix an issue with nodes not b… ([#175](https://github.com/binbashar/bb-devops-tf-infra-aws/issues/175))


<a name="v1.1.33"></a>
## [v1.1.33] - 2021-01-17

- BBL-24 | hashicorp vault cloud hvn and shared vpc peering


<a name="v1.1.32"></a>
## [v1.1.32] - 2021-01-14

- Refactor EKS layer to support the creation of multiple clusters ([#173](https://github.com/binbashar/bb-devops-tf-infra-aws/issues/173))


<a name="v1.1.31"></a>
## [v1.1.31] - 2021-01-13

- BBL-192 | pointing root context makefile to the latest ver to support mfa cache


<a name="v1.1.30"></a>
## [v1.1.30] - 2021-01-11

- Implement credentials caching in MFA script ([#171](https://github.com/binbashar/bb-devops-tf-infra-aws/issues/171))


<a name="v1.1.29"></a>
## [v1.1.29] - 2021-01-09

- BBL-453 | leaving only cron rclone backup circile ci job
- BBL-453 | passing aws keys through encrypted file
- BBL-453 | moving credentials to encrypted file
- BBL-453 | setting env vars at rclone ci stage
- BBL-453 | leaving rconf config only at bash script
- BBL-453 | re-adding creds setup to rclone bash script
- BBL-453 | rclone.conf cp via ci job cmd
- BBL-453 | adding some more rclone debugging related cmds to ci job
- BBL-453 | adding ls cmd for debugging
- BBL-453 | updating rclone script
- BBL-453 | adding sudo chown to rclone ci cmd
- BBL-453 | adding sudo to cp cmd
- BBL-453 | changing mv w/ cp to avoid permission denied with rclone.conf
- BBL-453 | adding read and write permissions to rclone.conf file before cp
- BBL-453 | moving rclone conf mgmt to circleci conf
- BBL-453 | updating circleci conf for make apply-rclone and script w/ sudo cp for config file
- BBL-453 | exporting ENV vars for rclone script
- BBL-453 | BBL-445 | adding sudo to make apply-rclone to fix permissions denied error
- BBL-443 | script will take care of rclone.conf home cp
- BBL-453 | using absolute path for rclone.conf
- BBL-453 | fixing decyrpt without chmod on latest makefile-lib ver
- BBL-453 | implementing make decrypt non interactive approach for rclone backup task
- BBL-453 | adjusting pip install ansible at circleci config
- BBL-453 | updating .circleci/config.yml to test drive to s3 backup job
- BBL-453 | upgrading lambda cost optimization module versions + fix exec time considering GTM-3


<a name="v1.1.28"></a>
## [v1.1.28] - 2021-01-04

- Fix an issue with MFA script failing to deduplicate the list of profiles that are parsed from Terraform config files ([#168](https://github.com/binbashar/bb-devops-tf-infra-aws/issues/168))


<a name="v1.1.27"></a>
## [v1.1.27] - 2020-12-19

- BBL-453 | minor fix adding missing resources to be excluded


<a name="v1.1.26"></a>
## [v1.1.26] - 2020-12-19

- BBL-453 | make format applied
- BBL-453 | shared/tools-cloud-scheduler-stop-start layer updated to use its latest stable module ver + associated tags added to EC2 tools
- BBL-453 | apps-devstg/tools-cloud-nuke layer updated to its latest stable module version
- BBL-453 | renaming shared/tools-webhooks with '--' suffix to reflext that this layer it's not currently provisioned


<a name="v1.1.25"></a>
## [v1.1.25] - 2020-12-18

- BBL-263 | updating tf-backend module its latest tf-0.14 version + terraform format
- BBL-263 | updating root context makefile w/ latest makefiles-lib ver + updating tf network module to its latest stable ver


<a name="v1.1.24"></a>
## [v1.1.24] - 2020-12-11

- BBL-450 | fixing make validate script for the new repo structure


<a name="v1.1.23"></a>
## [v1.1.23] - 2020-12-04

- Create Webhooks Proxy infrastructure resources ([#162](https://github.com/binbashar/bb-devops-tf-infra-aws/issues/162))


<a name="v1.1.22"></a>
## [v1.1.22] - 2020-12-02

- BBL-192 | testing latest makefile-lib ver witi import mfa
- BBL-192 | testing root with oaar-mfa + make import with mfa
- BBL-192 | updated root tf backend iam profile to use OrganizationAccountAccessRole
- BBL-192 | minor typo fix in var name
- BBL-192 | pointing makefile lib to its latest stable version
- BBL-192 | adding root OrganizationAccountAccessrole


<a name="v1.1.21"></a>
## [v1.1.21] - 2020-12-01

- BBL-192 | updating pritunl ssl cert renew inline comment steps


<a name="v1.1.20"></a>
## [v1.1.20] - 2020-11-30

- BBL-192 | make format applied
- BBL-192 | updating makefiles to use mfa + vpn ssl cert generation inline comments updated


<a name="v1.1.19"></a>
## [v1.1.19] - 2020-11-19

- BBL-192 | makefile-lib to latest version fixing makefile help output


<a name="v1.1.18"></a>
## [v1.1.18] - 2020-11-16

- BBL-446 | ci pre-commit integration + circleci slack notif improvement


<a name="v1.1.17"></a>
## [v1.1.17] - 2020-11-13

- BBL-445 | apps-prd/base-identities mfa for priviledged roles set to true
- BBL-445 | apps-devstg/base-identities mfa for priviledged roles set to true
- BBL-445 | security/base-identities mfa for priviledged roles set to true
- BBL-445 | shared/base-identities mfa for priviledged roles set to true
- BBL-445 | init-makefiles ref to latest ver


<a name="v1.1.16"></a>
## [v1.1.16] - 2020-11-09

- BBL-192 | udpating makefile lib ver to its latest stable ver
- BBL-192 | pointing to latest Makefile-lib version
- BBL-192 | security/base-identities apply validation + small sintaxt improvement


<a name="v1.1.15"></a>
## [v1.1.15] - 2020-11-09

- Improve MFA script to better handle error conditions, improve logs, improve documentation ([#155](https://github.com/binbashar/bb-devops-tf-infra-aws/issues/155))


<a name="v1.1.14"></a>
## [v1.1.14] - 2020-11-06

- Add support for multiple profiles on the MFA script ([#153](https://github.com/binbashar/bb-devops-tf-infra-aws/issues/153))


<a name="v1.1.13"></a>
## [v1.1.13] - 2020-11-01

- Merge branch 'master' of github.com:binbashar/le-tf-infra-aws
- BBL-XXX | minor sintaxt makefile improvement


<a name="v1.1.12"></a>
## [v1.1.12] - 2020-11-01

- Merge branch 'master' of github.com:binbashar/le-tf-infra-aws
- BBL-XXX | hot fix for backup-bb-gdrive-to-s3 ci job


<a name="v1.1.11"></a>
## [v1.1.11] - 2020-11-01

- BBL-XXX | hot fix for backup-bb-gdrive-to-s3 ci job


<a name="v1.1.10"></a>
## [v1.1.10] - 2020-10-29

- Refactor GuardDuty to favor the use of new modules ([#152](https://github.com/binbashar/bb-devops-tf-infra-aws/issues/152))


<a name="v1.1.9"></a>
## [v1.1.9] - 2020-10-26

- BBL-442 | readme.md update with error consideration
- BBL-442 | fixing iam replication policy


<a name="v1.1.8"></a>
## [v1.1.8] - 2020-10-26

- BBL-442 | adding layer dependencies for apps-devstg storage layer


<a name="v1.1.7"></a>
## [v1.1.7] - 2020-10-26

- BBL-442 | make pre-commit applied and .md files formated
- BBL-442 | make format applied
- BBL-442 | kms layer updated to allow s3 service + kms_key_dr layer added (us-east-2)
- BBL-442 | security/base-identities s3 demo user + group added + finops creds-self-management policy limited
- BBL-442 | apps-devstg/storage terraform-aws-s3-bucket full encrypted example with replication
- BBL-442 | renaming gpg keys with machine.prefix bot a clearer naming convention


<a name="v1.1.6"></a>
## [v1.1.6] - 2020-10-25

- BBL-438 | make pre-commit applied and mds files formated


<a name="v1.1.5"></a>
## [v1.1.5] - 2020-10-24

- BBL-438 | cross-layer minor improvements
- BBL-438 | kops s3 bucket with ssl request enforced + tf13 use + dns assoc with shared improved
- BBL-438 | notifications layer updated cross-org to enforce kms user managed key + minor sintaxt enhancements.
- BBL-438 | cdn-s3-frontend buckets layer updated with efornced ssl request policy
- BBL-438 | security-compliance layer cross-org updated with ApprovedAMI tag value
- BBL-438 | shared/storage enforcing ssl request via Bucket policy + minor sintaxt improvements
- BBL-438 | shared/tools-* ApprovedAMI var added + minor sintaxt improvements
- BBL-438 | upgrading makefile lib fixed version
- BBL-438 | makefile lib improvements applied


<a name="v1.1.4"></a>
## [v1.1.4] - 2020-10-24

- Adjust CloudWatch Authorization Alarm to reduce its noisiness ([#147](https://github.com/binbashar/bb-devops-tf-infra-aws/issues/147))


<a name="v1.1.3"></a>
## [v1.1.3] - 2020-10-22

- Implement GuardDuty with AWS Organization ([#145](https://github.com/binbashar/bb-devops-tf-infra-aws/issues/145))


<a name="v1.1.2"></a>
## [v1.1.2] - 2020-10-12

- BBL-432 | standarizing naming conevention with '-' (aws S3 and Dynamo resources verified and in sync)
- BBL-432 | upgrading security-compliance layer module versions


<a name="v1.1.1"></a>
## [v1.1.1] - 2020-10-12

- urgent-fix | patch release flag setup
- urgen-fix | makefiles typo corrected


<a name="v1.1.0"></a>
## [v1.1.0] - 2020-10-09

- BBL-381 | releasing minor ver
- BBL-381 | updating .gitignore to only exclude makefiles folder
- BBL-381 | makefile stand-alone approach implemented + README.md updated
- BBL-381 | adding pre-commit config + 1st standalone makefile update + terraform format cross layer
- BBL-381 | removing makefiles and files dirs
- Enable KMS on CloudTrail and CloudWatch Logs. Enforce SSL requests in VPC Flow Logs ([#141](https://github.com/binbashar/bb-devops-tf-infra-aws/issues/141))


<a name="v1.0.35"></a>
## [v1.0.35] - 2020-10-06

- Update Terraform state backends to enforce SSL requests ([#140](https://github.com/binbashar/bb-devops-tf-infra-aws/issues/140))


<a name="v1.0.34"></a>
## [v1.0.34] - 2020-10-02

- BBL-381 | fixing requires statement at circleci config
- BBL-381 | adding requires for sumologic collector workflow


<a name="v1.0.33"></a>
## [v1.0.33] - 2020-09-27

- Fix CloudTrail bucket policy which was mistakenly declared as a bucket instead of a bucket policy ([#139](https://github.com/binbashar/bb-devops-tf-infra-aws/issues/139))


<a name="v1.0.32"></a>
## [v1.0.32] - 2020-09-25

- Import AccessAnalyzer in Security. Also fix a data resource in Root's CloudTrail layer ([#138](https://github.com/binbashar/bb-devops-tf-infra-aws/issues/138))


<a name="v1.0.31"></a>
## [v1.0.31] - 2020-09-24

- BBL-381 | upgrading circleci vm executor


<a name="v1.0.30"></a>
## [v1.0.30] - 2020-09-17

- Import OrganizationAccountAccessRole in all accounts and enable MFA on it; also disable MFA on Security until the MFA script can support multi-profiles per layer ([#137](https://github.com/binbashar/bb-devops-tf-infra-aws/issues/137))


<a name="v1.0.29"></a>
## [v1.0.29] - 2020-09-16

- BBWW-57 | small binbash.com.ar update related to google search verification


<a name="v1.0.28"></a>
## [v1.0.28] - 2020-09-14

- Update and test DevStg and Prd accounts to support Terraform 13 ([#135](https://github.com/binbashar/bb-devops-tf-infra-aws/issues/135))


<a name="v1.0.27"></a>
## [v1.0.27] - 2020-09-11

- Update and test Shared account to support Terraform 13 ([#134](https://github.com/binbashar/bb-devops-tf-infra-aws/issues/134))


<a name="v1.0.26"></a>
## [v1.0.26] - 2020-09-11

- Update and test Root account to support Terraform 13 ([#133](https://github.com/binbashar/bb-devops-tf-infra-aws/issues/133))


<a name="v1.0.25"></a>
## [v1.0.25] - 2020-09-10

- Update and test Root account to support Terraform 13 ([#131](https://github.com/binbashar/bb-devops-tf-infra-aws/issues/131))


<a name="v1.0.24"></a>
## [v1.0.24] - 2020-09-08

- Enable the Terraform-AWS-MFA flow in Security and other minor related... ([#129](https://github.com/binbashar/bb-devops-tf-infra-aws/issues/129))


<a name="v1.0.23"></a>
## [v1.0.23] - 2020-09-07

- Refactor container-registry layer to simplify multiple repositories definition. Also refactor base-dns to leverage new AWS provider resources that support cross-account defined as code ([#128](https://github.com/binbashar/bb-devops-tf-infra-aws/issues/128))


<a name="v1.0.22"></a>
## [v1.0.22] - 2020-09-06

- Refactor all Terraform Makefiles to support again the approach that uses a separate config file for non-backend configuration entries in order to prepare for Terraform 0.13.1 and above ([#127](https://github.com/binbashar/bb-devops-tf-infra-aws/issues/127))


<a name="v1.0.21"></a>
## [v1.0.21] - 2020-09-04

- Terraform & AWS Authentication with MFA support ([#126](https://github.com/binbashar/bb-devops-tf-infra-aws/issues/126))


<a name="v1.0.20"></a>
## [v1.0.20] - 2020-08-27

- Increase max session duration to 3h in all accounts. Also fix a minor with AWS Setup Credentials script. ([#122](https://github.com/binbashar/bb-devops-tf-infra-aws/issues/122))


<a name="v1.0.19"></a>
## [v1.0.19] - 2020-08-19

- Sync up with latest implementation made for Flex; also refactored Shared DNS to favor the use of subfolders per domain ([#121](https://github.com/binbashar/bb-devops-tf-infra-aws/issues/121))


<a name="v1.0.18"></a>
## [v1.0.18] - 2020-08-19

- BBL-192 | making python aws-creds script executable + LICENSE.md


<a name="v1.0.17"></a>
## [v1.0.17] - 2020-08-14

- BBWW-41 | adding statics.binbash.com.ar for www.binbash.com.ar and future frontends.


<a name="v1.0.16"></a>
## [v1.0.16] - 2020-08-13

- Create helper script to setup AWS credentials ([#119](https://github.com/binbashar/bb-devops-tf-infra-aws/issues/119))


<a name="v1.0.15"></a>
## [v1.0.15] - 2020-08-06

- BBWW-43 | updating cdn-s3 for www.binbash.com.ar
- BBWW-43 | cdn-s3 module referenced to its latest version - proper tests have been carried out
- BBWW-43 | updating reference architecture for lately www.binbash.com.ar frontend release


<a name="v1.0.14"></a>
## [v1.0.14] - 2020-07-31

- BBL-192 minor fixes to shared/tools-vpn-server layer


<a name="v1.0.13"></a>
## [v1.0.13] - 2020-07-30

- BBL-192 base-identities password length set to >= 30


<a name="v1.0.12"></a>
## [v1.0.12] - 2020-07-29

- Refactor security folder in all accounts ([#115](https://github.com/binbashar/bb-devops-tf-infra-aws/issues/115))


<a name="v1.0.11"></a>
## [v1.0.11] - 2020-07-28

- BBL-209 apps-devstg/base-network -> nat-gw notif updated
- BBL-209 shared/base-networks NACLs implemented
- BBL-209 pointing kms module to its latest version
- BBL-209 apps-prd base-networks NACLs implemented
- BBL-209 apps-devstg/base-networks sintaxt improvement
- BBL-209 apps-devstg base-networks NACLs implemented
- Merge branch 'master' into BBL-209-nacls-routing-hardening
- BBL-209 apps-devstg/base-network -> adding NACLs


<a name="v1.0.10"></a>
## [v1.0.10] - 2020-07-28

- Rename Notifications SNS topic


<a name="v1.0.9"></a>
## [v1.0.9] - 2020-07-27

- Re-encrypt notifications secrets with the proper Vault passphrase ([#112](https://github.com/binbashar/bb-devops-tf-infra-aws/issues/112))


<a name="v1.0.8"></a>
## [v1.0.8] - 2020-07-27

- BBL-209 make format applied
- BBL-209 fix output value for notifications
- BBL-209 updating notifications output call name
- Merge branch 'master' into BBL-209-nacls-routing-hardening
- BBL-209 testing natgw notifications


<a name="v1.0.7"></a>
## [v1.0.7] - 2020-07-24

- Rename notifications resources in all accounts to remove 'bb' ([#110](https://github.com/binbashar/bb-devops-tf-infra-aws/issues/110))


<a name="v1.0.6"></a>
## [v1.0.6] - 2020-07-24

- BBL-191 suffix added to CloudTrial Alarms to ease its Slack channel identification
- BBL-191 make format applied


<a name="v1.0.5"></a>
## [v1.0.5] - 2020-07-24

- BBL-209 root/security/awscloudtrail slack security notifications activated
- BBL-209 variables.tf minor improvements
- BBL-209 improving root-long-notif sufix naming convention to ease its understanding when alerted via Slack (will be propagated for CloudTrail too)
- BBL-209 activating apps-prd and apps-devstg notifications for tools-monitoring slack channel
- BBL-209 Only private subnets traffic will be routed and permitted through VPC Peerings
- BBL-209 Improving config.tf parametrized convention w/ var.project wherever possible


<a name="v1.0.4"></a>
## [v1.0.4] - 2020-07-21

- BBL-192 updating .gitignore and adding gpg public keys


<a name="v1.0.3"></a>
## [v1.0.3] - 2020-07-20

- Global config ([#106](https://github.com/binbashar/bb-devops-tf-infra-aws/issues/106))


<a name="v1.0.2"></a>
## [v1.0.2] - 2020-07-17

- BBL-173 base-tf-backend layer improved to store tf state at s3
- BBL-173 updating Slack notification channels with its updated names
- BBL-173 Makefile terraform12 import-rm improvement


<a name="v1.0.1"></a>
## [v1.0.1] - 2020-07-10

- BBL-167 minor base-dns shared fix


<a name="v1.0.0"></a>
## [v1.0.0] - 2020-07-10

- BBL-167 CircleCI and scripts updated to follow var.project parameter config cross-org
- BBL-167 Updating Makefiles to follow var.project parameter cross-org config
- BBL-167 adding var.project parameter to aws provider config cross-org
- BBL-167 releasing as major achieving full tf-0.12 migration (kops exception temporally disregarded) + upgraded .mk include improved approach
- BBL-167 missing apps-devstg account .mk include based Makefiles added
- BBL-167 apps-prd acct cross-layer upgraded Makefile include .mk introduced
- BBL-167 missing root account .mk include based Makefiles added
- BBL-167 root/cost-mgmt layer migrated to tf-0.12 + small fix to root/security/cloudtrail var
- BBL-167 root acct cross-layer upgraded Makefile include .mk introduced
- BBL-167 security acct cross-layer upgraded Makefile include .mk introduced
- BBL-167 shared acct cross-layer upgraded Makefile include .mk introduced
- BBL-167 cross-org upgrade for terraform-aws-notify-slack module to its latest stable v3.3.0 version
- BBL-167 apps-devstg/k8-kops layers tf docker cmd based introduced
- BBL-167 updagrading terraform-aws-iam module to its latest stable v2.12.0 version
- BBL-167 Makefiles updated to support docker bash interactive for tf-0.12 + kops custom cmd
- BBL-167 kops fully dockerized scripts + aws creds limited to client scope
- BBL-167 migrating root/cost-mgmt layer to tf 0.12 (WIP)
- BBL-167 updagrading base-network module version cross-org
- BBL-167 apps-devstg account cross-layer migrated to include .mk reusable approach in Makefiles
- BBL-167 migrating to include .mk reusable approach


<a name="v0.1.40"></a>
## [v0.1.40] - 2020-07-07

- BBWW-44 re-ading chown to .aws creds dir
- BBWW-44 updating req aws provider to 2.69
- BBWW-44 updating circlejob to its latests cross-project state
- BBWW-44 updating README.md to reflect updated leverage doc
- BBWW-44 updating leverage doc link in README.md
- BBWW-44 1st updato for .mk approach migration
- BBWW-44 make format applied
- BBWW-44 updating req to latest stable terraform ver 0.12.28


<a name="v0.1.39"></a>
## [v0.1.39] - 2020-07-01

- BBL-282: Create infra for Prometheus and Grafana ([#90](https://github.com/binbashar/bb-devops-tf-infra-aws/issues/90))


<a name="v0.1.38"></a>
## [v0.1.38] - 2020-06-23

- BBL-119 fixing bb logo figure url
- BBL-119 figures update


<a name="v0.1.37"></a>
## [v0.1.37] - 2020-06-23

- BBL-119 documentation setup as an stand alone repo https://github.com/binbashar/le-ref-architectre-doc


<a name="v0.1.36"></a>
## [v0.1.36] - 2020-06-23

- BBL-119 mkdocs-gb site/ test


<a name="v0.1.35"></a>
## [v0.1.35] - 2020-06-23

- BBL-19 fixing Mkdocs site_url


<a name="v0.1.34"></a>
## [v0.1.34] - 2020-06-23

- BBL-19 minor figure name update in README.md
- BBL-19 minor figure name update in README.md
- BBL-19 updating README.md figures
- BBL-19 docs/examples section
- BBL-19 docs/user-guide section
- BBL-19 docs/how-it-works section
- BBL-19 docs/images adding pending figures
- BBL-19 Main Mkdocs files mkdocs.yml + index.md among others
- BBL-19 docs/images all the current icons and figures for the doc
- BBL-19 Adding Mkdos related Makefile cmds
- BBL-19 Updating shared/storage gdrive backup backup to avoid object versioning resulting in a bucket oversize.
- BBL-19 Removing [@doc](https://github.com/doc) folder to use Mkdocs default docs one.


<a name="v0.1.33"></a>
## [v0.1.33] - 2020-06-15

- BIZUP-36 circleci cron expression setup to be monthly as expected


<a name="v0.1.32"></a>
## [v0.1.32] - 2020-06-15

- BIZSUP-36 increasing no_output_timeout to avoid "Too long with no output (exceeded 10m0s): context deadline exceeded"


<a name="v0.1.31"></a>
## [v0.1.31] - 2020-06-14

- BIZSUP-36 increasing no_output_timeout to avoid "Too long with no output (exceeded 10m0s): context deadline exceeded"


<a name="v0.1.30"></a>
## [v0.1.30] - 2020-06-12

- BIZSUP-36 shared/base-identities -> migrating groups to terraform-aws-iam module latest version + backup policy update to be reusable for both backup.s3 group + FinOps role
- BIZSUP-36 apps-devstg/base-identities -> migrating groups to terraform-aws-iam module latest version
- BIZSUP-36 migrating groups to terraform-aws-iam module latest version and removing iam-self-mgmt policy since the module takes care of this
- BIZSUP-36 updating .gitignore to deny rclone.conf
- BIZSUP-36 updating .gitignore to deny rclone.conf sensitive files + allowing gpg public keys + uploading current user public keys


<a name="v0.1.29"></a>
## [v0.1.29] - 2020-06-12

- Merge branch 'master' into BIZSUP-36-s3-bb-gdrive-bucket
- BIZSUP-36 Adding CircleCI automated drive to s3 backup job


<a name="v0.1.28"></a>
## [v0.1.28] - 2020-06-11

- BIZUP-36 rclone script for automated backup - pending to cron it via CircleCI job
- BIZUP-36 adding aws s3 Bucket with lifecycle policies for gdrive backup
- BIZUP-36 adding user and group backup.s3 for monthly bb gdrive so s3 backup
- BIZUP-36 minor makefile encrypt cmd fix


<a name="v0.1.27"></a>
## [v0.1.27] - 2020-06-05

- BBL-167 root-org to root acct renamed following cross-project naming convention
- BBL-167 shared acct cross-layer naming convetion updated
- BBL-167 security acct cross-layer naming convetion updated
- BBL-167 root-org cross-layer naming convetion updated
- BBL-167 apps-prd cross-layer naming convetion updated
- BBL-167 apps-devstg cross-layer naming convetion updated


<a name="v0.1.26"></a>
## [v0.1.26] - 2020-05-29

- BBL-XXX allowing trusted avisor for DevOps role


<a name="v0.1.25"></a>
## [v0.1.25] - 2020-05-28

- BBL-XXX allowing trusted avisor for DevOps role


<a name="v0.1.24"></a>
## [v0.1.24] - 2020-05-27

- BBWW-131 removing policy since terraform-aws-iam group module takes care of this via  -> resource "aws_iam_policy" "iam_self_management" {...}
- BBWW-131 Updating Groups with terraform-aws-iam module + adding FinOps group ViewOnly Permissions


<a name="v0.1.23"></a>
## [v0.1.23] - 2020-05-22

- BBL-299 adding ec2_fleet layer for testing purposes, -- sufix reflects this it's not currently orchestrated
- BBL-299 upgrading and testing latest terraform-aws-vpc module version cross org
- BBL-299 adding auditor group and user as pre-req for some sec related tools
- BBL-299 improving make_diagram scripts
- BBL-229 Adding CloudMater and SecurityViz diagrams per account
- BBL-299 reviewing Makefile dockerized TF_CMD_PREFIX to grant terraform-aws-provider aws cred configs (shared_credentials_file = "~/.aws/bb-le/config") are properly managed
- BBL-229 updating .gitignore


<a name="v0.1.22"></a>
## [v0.1.22] - 2020-05-22

- BBL-299 adding data dir
- BBL-229 small naming file generation and naming convention improvement
- BBL-299 updating Makefile to set permissions after execution
- BBL-299 segregating components diagram from sg diagram
- BBL-229 Minor readme update
- BBL-229 Adding auditor group + auditor-ci user for CloudMapper and other future tools / adding module to populate dummy nano ec2s in order to improve CloudMapper diagrams
- BBL-299 updating terraform-aws-provider req cross layer
- BBL-229 Adding aws-account diagram via CloudMapper


<a name="v0.1.21"></a>
## [v0.1.21] - 2020-05-21

- BBL-298 Makefile cmd to support antonbabenko/terraform-cost-estimation


<a name="v0.1.20"></a>
## [v0.1.20] - 2020-05-19

- BBWW-45 shared/infra_vpn-server renaming layer + updating to latest module version v0.3.9
- BBWW-45 shared renaming layers under the new naming convetion
- BBWW-45 security renaming layers under the new naming convetion
- BBWW-45 root-org renaming layers under the new naming convetion
- BBWW-45 apps-prd renaming layers under the new naming convetion
- BBWW-45 apps-devstg renaming layers under the new naming convetion


<a name="v0.1.19"></a>
## [v0.1.19] - 2020-05-14

- BBWW-34 shared/9_jenkins renaming layer with '--¿ suffix to reflect it's not orchestrated
- BBWW-34 shared/11_eskibana renaming layer with '--¿ suffix to reflect it's not orchestrated
- Merge branch 'master' into BBWW-34-cf-s3
- BBWW-34 make format applied
- BBWW-34 replacing Makefile w/ proper symbolic-link
- BBWW-34 Minor 2ry provider tf code sintaxt improvement
- BBWW-34 apps-prd/12_cdn_s3_frontend adding cloudfront + s3 layer for prd.aws.binbash.com.ar
- BBWW-34 apps-prd/4_security_certs adding AWS AMC related layer
- BBWW-34 sync with customer latest ver
- BBWW-34 apps-devstg/12_cdn_s3_frontend adding cloudfront + s3 layer for dev.aws.binbash.com.ar
- BBWW-34 apps-devstg/4_security_certs adding AWS ACM layer
- BBWW-34 shared/5_dns removing unused comment


<a name="v0.1.18"></a>
## [v0.1.18] - 2020-05-11

- Create infrastructure for ElasticSearch and Kibana ([#79](https://github.com/binbashar/bb-devops-tf-infra-aws/issues/79))


<a name="v0.1.17"></a>
## [v0.1.17] - 2020-05-07

- BBL-297 Adding validation in Makefile changelog cmd to fix CircleCi error
- BBL-297 disabling shared account ec2s enhanced monitoring


<a name="v0.1.16"></a>
## [v0.1.16] - 2020-04-24

- BBL-250 segregating cp cmd for circleci aws cred config
- BBL-250 adding -R to avoid cp ommiting dir error in circleci aws cred setup
- BBL-250 using cp instead of mv for circleci job aws creds config
- BBL-250 adding circile cmd to move AWS credential inside the proper project folder
- BBL-250 pointing to updated Makefile for format-check CI validation
- BBL-250 updating root Makefile + make format
- BBL-250 adding schedule start daily morning for pritunl server
- BBL-250 README.md release mgmt added + figures resizeing
- BBL-250 shared/10_cloud-scheduler-stop-start layer added to daily stop tagged EC2s at midnight eg: jenkins-master
- BBL-250 apps-devstg/7_cloud_nuke layer updated with latest module and sixtaxt var improvement
- BBL-250 adding / updating terraform related .gitignores
- BBL-250 Makefiles cross layer update
- BBL-250 terraform aws provider version update + shared credentials to use .aws/project credentials folder
- BBL-250 makefiles/terraform12 updated to use .aws/project credentials fodler + removed makefiles not necessary any more
- BBL-250 makefiles/terraform11 updated to use .aws/project credentials fodler + removed makefiles not necessary any more
- BBL-250 .gitignore updated
- BBL-250 shared/9_jenkins iam layer updated to to be fully independent via ec2_profile
- OPS-250 upgrading from terraform version 0.12.20 to 0.12.24


<a name="v0.1.15"></a>
## [v0.1.15] - 2020-04-22

- BBL-245 Fix every module import url from `git` to `https` [#66](https://github.com/binbashar/bb-devops-tf-infra-aws/issues/66)


<a name="v0.1.14"></a>
## [v0.1.14] - 2020-04-20

- Create AWS resources for deploying a Jenkins server ([#64](https://github.com/binbashar/bb-devops-tf-infra-aws/issues/64))


<a name="v0.1.13"></a>
## [v0.1.13] - 2020-04-07

- BBL-226 updating ISSUES templates and config to get integration still not working


<a name="v0.1.12"></a>
## [v0.1.12] - 2020-04-07

- BBL-226 updating ISSUES template config to fix integration


<a name="v0.1.11"></a>
## [v0.1.11] - 2020-04-07

- BBL-226 drier .circleci/config setup
- BBL-226 adding .github dir w/ ISSUES and PRs templates
- BBL-226 .chlog, .gitignore and README.md minor updates
- BBL-226 | refarch sync ([#58](https://github.com/binbashar/bb-devops-tf-infra-aws/issues/58))
- BBL-226 security/2_identities removing users
- BBL-226 updating CHANGELOG.md templates and configs for improved output
- BBL-226 shared/5_dns layer updated segregating DNS zones + shared/7_vpn-server layer fmt
- BBL-225 root-org/3_organizations Mafile context var updated
- BBL-226 apps-prd/5_dns layer few resource renaming updates
- BBL-226 apps-devstg layers update, few canonical format + resource renaming
- BBL-226 minor comment sintaxt improvement


<a name="v0.1.10"></a>
## [v0.1.10] - 2020-03-24

- Test drive postgres provider. ([#57](https://github.com/binbashar/bb-devops-tf-infra-aws/issues/57))


<a name="v0.1.9"></a>
## [v0.1.9] - 2020-02-27

- BBL-177 secureing VPN Server + info for cert update and new users config sharing
- BBL-177 security/2_identities adding and ordering layer outputs


<a name="v0.1.8"></a>
## [v0.1.8] - 2020-02-25

- BBL-177 security/2_identities alfredo.pardo user added to DevOps Group
- BBL-177 security/2_identities adding alfredo.pardo to DevOps Group
- BBL-177 root-org/2_identities updated with finops_root_org group + marcelo.beresvil memeber user
- BBL-177 removing not necessary files since related issue is in place (https://github.com/binbashar/bb-devops-tf-infra-aws/issues/49)


<a name="v0.1.7"></a>
## [v0.1.7] - 2020-02-13

- BBL-199 apps-devstg/11_ec2_fleet_ansible -> adding DNS capabilities from shared/5_dns account in order to simplify ansible .hosts setup
- BBL-199 applying terraform fmt
- BBL-199 apps-devstg/11_ec2_flee_ansible layer added in order to test ansible playbook against a fleet of vms
- BBL-199 some sintaxt fixes
- BBL-199 make encyrpt/decrypt now fully supported via Makefiles


<a name="v0.1.6"></a>
## [v0.1.6] - 2020-02-12

- Grant MFA permissions to standard console policy by default. ([#41](https://github.com/binbashar/bb-devops-tf-infra-aws/issues/41))


<a name="v0.1.5"></a>
## [v0.1.5] - 2020-02-12

- fixing figures source links


<a name="v0.1.4"></a>
## [v0.1.4] - 2020-02-12

- Merge branch 'master' into BBL-184-bb-devops-tf-infra-aws-issue-31
- BBL-184 fixing symlink
- BBL-184 shared Makefiles replaced by [@bin](https://github.com/bin)/Makefiles/terraform12 symlinks
- BBL-184 security Makefiles replaced by [@bin](https://github.com/bin)/Makefiles/terraform12 symlinks
- BBL-184 root-org Makefiles replaced by [@bin](https://github.com/bin)/Makefiles/terraform12 symlinks
- BBL-184 apps-prd Makefiles replaced by [@bin](https://github.com/bin)/Makefiles/terraform12 symlinks
- BBL-184 apps-devstg Makefiles replaced by [@bin](https://github.com/bin)/Makefiles/terraform12 symlinks
- BBL-184 root context Makefiles updated to use new structer and symlinks ever possible.
- BBL-184 folder structure improvement to [@doc](https://github.com/doc)/figures
- BBL-184 folder structure improvement to [@bin](https://github.com/bin)/scripts
- BBL-184 folder structure improvement to [@bin](https://github.com/bin)/makefiles - folder renaming
- BBL-184 folder structure improvement to [@bin](https://github.com/bin)/makefiles
- Update readme to remove parts moved to the wiki... ([#35](https://github.com/binbashar/bb-devops-tf-infra-aws/issues/35))
- BBL-184 fix for [Errno 13] Permission denied: '/home/circleci/.aws/credentials' by adding sudo to chown
- BBL-184 fix for [Errno 13] Permission denied: '/home/circleci/.aws/credentials'
- BBL-184 fixing ../../[@makefiles](https://github.com/makefiles)/terraform12/Makefile.terraform12: No such file or directory
- BBL-184 shared account cross-layers canonically formated w/ terraform fmt
- BBL-184 shared account cross-layer Makefiles update to use [@Makefile](https://github.com/Makefile) reusable lib
- BBL-184 security account cross-layers canonically formated w/ terraform fmt
- BBL-184 security account cross-layer Makefiles update to use [@Makefile](https://github.com/Makefile) reusable lib
- BBL-187 root-org/5_cost-mgmt and root-org/6_notifications layers updated (aws budget WIP)
- BBL-184 root-org account cross-layers canonically formated w/ terraform fmt
- BBL-184 root-org account cross-layer Makefiles update to use [@Makefile](https://github.com/Makefile) reusable lib
- BBL-184 apps-prd account cross-layers canonically formated w/ terraform fmt
- BBL-184 apps-prd account cross-layer Makefiles update to use [@Makefile](https://github.com/Makefile) reusable lib
- BBL-184 apps-devstg/8_k8s_kops layer removing not necessary files
- BBL-184 apps-devstg account layers canically formated w/ terraform fmt
- BBL-184 apps-devstg account cross layer Makefiles update to use [@Makefile](https://github.com/Makefile) reusable lib
- BBL-184 root context Makefiles upgraded to use reusable [@Makefile](https://github.com/Makefile) folder
- BBL-184 [@Makefile](https://github.com/Makefile) lib folder reorganized
- BBL-184 adding comment to fmt -check because of combined tf11 and tf12 code in repo
- BBL-184 adding [@makefile](https://github.com/makefile) centralized library folder with reusable cross-project Makefiles


<a name="v0.1.3"></a>
## [v0.1.3] - 2020-02-06

- BBL-167 shared/5_dns layer cross DNS assoc updated
- BBL-167 shared/4_security layer updated
- BBL-167 shared/3_network layer updated to follow the naming convention
- BBL-167 security acct layers updated
- BBL-167 root-org/4_security layer updated
- BBL-167 root-org/3_organizations imported, updated and applied
- BBL-167 root-org/2_identities layer updated
- BBL-167 apps-prd/config files updated
- BBL-167 apps-prd/6_notifications layer updated and orchestrated
- BBL-167 apps-prd/5_dns layer updated and orchestrated
- BBL-167 apps-prd/4_security layer updated and orchestrated
- BBL-167 apps-prd/3_network layer updated and orchestrated
- BBL-167 apps-prd/2_identities layer updated and orchestrated
- BBL-167 apps-prd/1_tf-backend layer updated and orchestrated
- BBL-167 apps-devstg layers updated to follow naming convention
- BBL-167 apps-devstg layers variables and Makefiles updated
- BBL-167 apps-devstg/3_network layer updated
- BBL-167 CloudTrail Org variable removed and injected directly from security account tf data source
- BBL-167 Makefiles terraform dockerized cmd prefix has been improved with -w (working directory)
- BBL-167 README.md updated with aws profile config reference file


<a name="v0.1.2"></a>
## [v0.1.2] - 2020-02-06

- Set theme jekyll-theme-slate


<a name="v0.1.1"></a>
## [v0.1.1] - 2020-02-05

- BBL-167 updating job name for exec consistency
- BBL-167 CircleCI and Makefile update to test release mgmt patch looks fine


<a name="v0.1.0"></a>
## [v0.1.0] - 2020-02-05

- BBL-167 updating CircleCI job and Makefile.release in order to pass the VERSION_NUMBER: patch, minor or major as an ENV VAR
- BBL-167 shared/8_jenkins-vault layer temporally deleted
- BBL-167 shared/8_container_registry layer updated
- BBL-167 shared/7_vpn-server layer updated
- BBL-167 shared/6_notifications layer updated and orchestrated
- BBL-167 shared/5_dns layer updated
- BBL-167 shared/4_security + shared/4_security_compliance layers updated
- BBL-167 shared/3_network layer updated
- BBL-167 shared/2_identities layer updated
- BBL-167 shared/1_tf-backend layer updated
- BBL-167 security configs segregated and update (backend.config, base.config and extra.config)
- BBL-167 security/6_notifications layer added
- BBL-167 security/5_organization layer deleted
- BBL-167 security/2_secrets layer deleted
- BBL-167 security/2_identities layer renamed and updated
- BBL-167 security/1_tf-backend layer updated
- BBL-167 apps-prd configs added
- BBL-167 apps-prd/9_backups placeholder layer added
- BBL-167 apps-prd/6_notifications placeholder layer added
- BBL-167 apps-prd/5_dns placeholder layer added
- BBL-167 apps-prd/4_security + apps-prd/4_security_compliance placeholder layers added
- BBL-167 apps-prd/3_network placeholder layer added
- apps-prd/2_identities placeholder layer added
- BBL-167 apps-prd/1_tf-backend placeholder layer added
- BBL-167 root-org/2_identities layer added
- BBL-167 root-org/3_organizations layer added (NOT IMPORTED YET)
- BBL-167 root-org config files segregated and updated -> backend.config, base.config and extra.cofig.
- BBL-167 root-org/6_notifications layer renamed and orchestrated w/ latest ver
- BBL-167 root-org/4_security and root-org/4_security_compliance layers renamed and updated
- BBL-167 root-org/5_cost_mgmt layer renamed (NOT MIGRATED to TF-0.12 yet!!!)
- BBL-167 root-org/1_tf-backend layer updated
- BBL-167 apps-devstg/10_databases_mysq + apps-devstg/10_databases_psql layers placesholders added
- BBL-167 Canonial formatting w/ terraform fmt
- BBL-167 config tf files backend.config, base.config, extra.config updated
- BBL-167 apps-devstg/9_store + apps-devstg/9_backups layers updated
- BBL-167 apps-devstg/8_k8s_kops layer updated with latest ref-architecture
- BBL-167 apps-devstg/8_k8s_eks layer updated to use managed nodes
- BBL-167 apps-devstg/7_cloud-nuke layer updated
- BBL-167 apps-devstg/6_notifications layer applied
- BBL-167 apps-devstg/5_dns layer updated
- BBL-167 apps-devstg/4_security + apps-devstg/4_security_compliance layers updated
- BBL-167 apps-devstg/3_network update
- BBL-167 apps-devstg/2_identities updated
- BBL-167 apps-devstg/1_tf-backend updated
- BBL-167 updating std repo files .gitignore, Makefile and README.md
- BBL-167 updating section header sizes
- BBL-167 updating section header sizes
- BBL-167 updating IAM figure size
- BBL-167 adding new AWS IAM reference figure for README.md
- BBL-167 adding Network and IAM sections.
- BBL-167 Full README.md update


<a name="v0.0.3"></a>
## [v0.0.3] - 2020-01-27

- BBL-167 adding comment for future release when tf-0.12 is fully supported
- BBL-167 Read More official AWS links added
- BBL-167 minor format and comment updates in shared files
- BBL-167 terraform apply updated to use local binary since there are local-exec resources declared in this layers
- BBL-167 shared/4_security_compliance canonical terraform fmt applied
- BBL-167 placeholder shared/6_notifications layer has been added
- BBL-167 shared/6_dns renamed to shared/5_dns + tf-0.12 migration in place
- BBL-167 shared/5_network renamed to shared/3_network + tf-0.12 migration
- BBL-167 shared/3_identities renamed to shared/2_identities
- shared/2_secrets layer deleted since we use an in-layer secret mgmt approach -> Will upload an RDS layer with this code soon.
- BBL-167 shared/1_tf-backend tf-0.12 update
- BBL-167 /dev renamed to /apps-devstg to follow the Ref Architecture naming convention
- BBL-167 canonical terraform fmt to Security Account layer
- BBL-167 canonical terraform fmt
- BBL-167 fully funcitonal terraform-aws-kops based on https://github.com/binbashar/bb-devops-tf-aws-kops
- BBL-167 dev/8_k8s_eks updated to use latest 8.1.0 module version + managed nodes code instantiation (needs further testing)
- BBL-167 dev/config -> backend, base and extra configs declared and fully functional for ever dev/tf-layer
- BBL-167 dev/7_cloud-nuke updated to support segregated config files + canonical tf fmt
- BBL-167 dev/9_notifications renamed to dev/6_notifications + canonical fmt + segregated file support + module update
- BBL-167 dev/5_dns renamed to dev/6_dns, DNS assoc code updated + canonical format terraform fmt + segregated vars support
- BBL-167 dev/4_security_compliance layer updated to support segregated config files + canonical terraform fmt
- BBL-167 dev/4_security layer module versions updated + canonical terraform fmt
- BBL-167 dev/5_network to dev/3_network renaming, VPC module to latest + Peering code updated (enabled flags added)
- BBL-167 dev/3_identities to dev/2_identities renaming
- dev/2_secrets layer deleted since we use an in-layer secret mgmt approach -> Will upload an RDS layer with this code soon.
- BBL-167 dev/1_tf-backend fully migrated and tested with tf-0.12 + segregated config files
- BBL-167 Dev acct main Makefile cmd updated -> terraform fmt -recursive (to link every code layer)
- BBL-167 Ref Arch AWS Organizations diagram updated


<a name="v0.0.2"></a>
## [v0.0.2] - 2020-01-17

- BBL-167 updating bb-aws-org figure size
- BBL-167 compressing bb-aws-org figure
- BBL-167 updating bb-aws-org diagram
- BBL-167 adding organizations diagram figure to README.md
- BBL-167 try figure url fix with private folder ref
- BBL-167 try figures url fix


<a name="v0.0.1"></a>
## [v0.0.1] - 2020-01-17

- BBL-167 standard files and CircleCI related files added for automated tests and release mgmt
- BBL-167 small update on variable description for root account
- BBL-167 Adding Doc related files, adding Makefile for static code analysis and automated release mgmt.
- BBL-167 several dev account layers updated
- BBL-167 dev/9_notifications layer added tested and fully supporting tf-0.12 - composible with any SNS req
- BBL-167 README.md udpated with some more details
- BBL-167 dev/5_network and dev/6_dns layers fully tested and migrated to tf-0.12
- BBL-167 dev/4_security implementing module terraform-aws-cloudtrail-cloudwatch-alarms
- BBL-167 dev/3_identities comments sintaxt updated
- BBL-167 dev/3_identities layer fully tested and migrated to tf-0.12 - standarized to use: https://github.com/binbashar/terraform-aws-iam/tree/master/modules/iam-assumable-role
- BBL-167 dev/2_secrets layer fully tested and migrated to tf-0.12 - remember '--' represents that the layer is not currently created on AWS.
- BBL-167 dev/1_tf_backend layer fully tested and migrated to tf-0.12
- BBL-167 Makefiles have been updated to support both dockerized and non-dockerized terraform apply cmd
- BBL-167 Shared Acct network layer migrated to tf0.12 with latest module version
- BBL-167 Shared Acct dns layer segregated and migrated to tf0.12
- BBL-54 Pritunl VPN server recreated with new tf0.12 module and new bb leverage ansible playbook
- BBL-167 forlders have been renamed in Shared Acct: jenkins and containers
- BBL-167 Dev Account EKS and Kops folders renamed
- BBL-167 Dev Account nw layer migrated to tf0.12 w/ latest module version
- BBL-167 renaming cloud-nuke folder
- BBL-167 Dev Acct DNS layer segregated and migrated to tf0.12
- BBL-119 clear foot-print in public key
- BBL-119 minor updates
- BBL-119 adding reference K8s Kops code - still needs to be battle tested
- BBL-119 adding reference EKS code - still needs to be battle tested
- BBL-153 config layer in sec account
- BBL-153 config perssions for DevOps role in sec account
- BBL-153 finishig ref arch config code
- BBL-119 pending makefile update
- BBL-153 aws config ref code
- BBL-119 pre-reqs IAM, Security and tf config updates
- BBL-119 updating main.config and backend.config files cross-org
- Minor Pritunl tf code updates
- BBL-119 pre-reqs shared network layer updates
- BBL-119 pre-reqs dev network layer updates
- BBL-119 pre-steps destroying jenkins related resources and renaming folder with '--' as a convention for destroyed state layers
- .hosts rollback
- jenkins stack temporary destroyed to save costs
- BBL-146 updating makefiles + IAM roles and policies for cost controls - control access to regions or resource types.
- lambda nuke implemented except for vpc,s3 and dynamodb
- Merge branch 'master' into BBL-33-lambda-nuke-dev-acct
- BBL-33 addding lambda nuke for dev account
- BBL-119 resolving conflicts
- Adding permissions for terratest
- testing git secrets
- testing git secrets
- BBL-119 updating budget treshold to 75% + instanciating latest tf-aws-cost-budget module version
- BBL-119 updating deploy-master role policy for dev account to test tf-backend 0.12 module
- BBL-122 adding circle.ci user for CI tests integration
- BBL-122 updating terraform output with dockerized cmd
- BBL-121 testing policy for sns budget permissions.


<a name="v0.0.1-alpha1"></a>
## v0.0.1-alpha1 - 2019-07-22

- Merge branch 'master' into BBL-81-jenkins - fixing conflicts
- fixing conflicts
- Merge branch 'master' of github.com:binbashar/bb-devops-tf-infra-aws
- GCP jenkins dns updated
- shared account jenkins ec2 makefile updated and referenced to new leverage source module
- shared account pritunl makefile update and reference to new leverage source module
- Updating shared account makefiles and referenced to new leverage tf source modules
- updating sec account makefiles and referencing to the new leverage tf modules source.
- update root-org account makefiles and referencing leverage tf source modules
- Dev account update makefiles and external module referenced to leverage ones
- Updating .gitignore
- BBL-33 moving backend configs to another folder test.
- Merge branch 'BBL-33-billing-review' of github.com:binbashar/bb-devops-tf-infra-aws into BBL-33-billing-review
- updating .gitignore
- BBL-33 root org cost-mgmt and sec resrouces in place.
- Added gonzalo martinez to devops group
- fixing conflicfts
- fixing conflicfts
- BBL-33 updating .gitignore
- BBL-33 adding new root account and deps
- BBL-33 adding new root account and deps
- BBL-33 adding new root account and deps
- BBL-33 adding new root account
- BBL-33 adding new root account
- BBL-33 adding new root account
- BBL-33 nat gateway disable in binbash-dev account for cost saving purposes
- BBL-33 nat gateway disable in binbash-dev account for cost saving purposes
- BBL-33 nat gateway disable in binbash-dev account for cost saving purposes
- BBL-33 diego.ojeda gpg key updated for binbash-sec account iam user.
- BBL-33 diego.ojeda gpg key updated for binbash-sec account iam user.
- BBL-33 updating vault ansible role to it latest stable from galaxy
- BBL-33 updating vault ansible role to it latest stable from galaxy
- BBL-33 pre-step updating tf aws provider dep to 2.10 & readme.md
- BBL-33 pre-step updating tf aws provider dep to 2.10 & readme.md
- BBL-33 pre-steps updating every Makefile to be selfdoc and support make diff cmd
- BBL-33 pre-steps updating every Makefile to be selfdoc and support make diff cmd
- BBL-37 adding google auth plugin and updating roles readme.md files
- BBL-37 adding google auth plugin and updating roles readme.md files
- BBL-37 jenkins file cleanup
- BBL-37 jenkins file cleanup
- BBL-37 jenkins.aws.binbash.com.ar v1 done
- BBL-37 jenkins.aws.binbash.com.ar v1 done
- BBL-36 clearing blok from pritunl post-task role
- BBL-36 clearing blok from pritunl post-task role
- BBL-36 moving openvpn-pritunl ansible post-tasks to a role
- BBL-36 moving openvpn-pritunl ansible post-tasks to a role
- BBL-37 jenkins ansible play initial commit
- BBL-37 jenkins ansible play initial commit
- BBL-37 openvon ansible var name update - jenkins module name update
- BBL-37 openvon ansible var name update - jenkins module name update
- BBL-36 and BBL-37 updates
- BBL-36 and BBL-37 updates
- BBL-36 using tags and vaul-pass vars in ansible provisioning module
- BBL-36 remove ansible-play commented line
- BBL-36 openvpn ec2 type update and inline comments added
- BBL-36 standalone mongodb role setup
- BBL-36 adding comments related to pending readme updates
- BBL-16 OpenVPN Pritunl code 1st version tested
- BBL-16 pritunl udp ports in place, ansible provisioner comments added
- BBL-16 - PR[#4](https://github.com/binbashar/bb-devops-tf-infra-aws/issues/4) fix vars rename and clean-up based on [@diego](https://github.com/diego)-ojeda-binbash comments
- BBL-16 cross-org network layer in place
- BBL-16 cross-org network layer consolidation
- BBL-16 fixing account ids for dev account
- BBL-16 tf-backend bucket keys updated for dev account
- BBL-16 org accounts setup
- BBL-16 shared and sec accounts sec, iam, vpc, openvpn in place - BBL-32 blocker
- BBL-16 tool ec2 tf segregated by aws service layer and start full parameter approach
- BBL-16 security account finished, shared account baseline aws layers in place
- BBL-16 cloudtrail.tf updates
- BBL-16 aws sec account indentities in place
- BBL-16 tf-backend created for sec + users account :)
- BBL-16 binbash org baseline/placeholders files


[Unreleased]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.3.74...HEAD
[v1.3.74]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.3.73...v1.3.74
[v1.3.73]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.3.72...v1.3.73
[v1.3.72]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.3.71...v1.3.72
[v1.3.71]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.3.70...v1.3.71
[v1.3.70]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.3.69...v1.3.70
[v1.3.69]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.3.68...v1.3.69
[v1.3.68]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.3.67...v1.3.68
[v1.3.67]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.3.66...v1.3.67
[v1.3.66]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.3.65...v1.3.66
[v1.3.65]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.3.64...v1.3.65
[v1.3.64]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.3.63...v1.3.64
[v1.3.63]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.3.62...v1.3.63
[v1.3.62]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.3.61...v1.3.62
[v1.3.61]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.3.60...v1.3.61
[v1.3.60]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.3.59...v1.3.60
[v1.3.59]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.3.58...v1.3.59
[v1.3.58]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.3.57...v1.3.58
[v1.3.57]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.3.56...v1.3.57
[v1.3.56]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.3.55...v1.3.56
[v1.3.55]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.3.54...v1.3.55
[v1.3.54]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.3.53...v1.3.54
[v1.3.53]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.3.52...v1.3.53
[v1.3.52]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.3.51...v1.3.52
[v1.3.51]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.3.50...v1.3.51
[v1.3.50]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.3.49...v1.3.50
[v1.3.49]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.3.48...v1.3.49
[v1.3.48]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.3.47...v1.3.48
[v1.3.47]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.3.46...v1.3.47
[v1.3.46]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.3.45...v1.3.46
[v1.3.45]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.3.44...v1.3.45
[v1.3.44]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.3.43...v1.3.44
[v1.3.43]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.3.42...v1.3.43
[v1.3.42]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.3.41...v1.3.42
[v1.3.41]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.3.40...v1.3.41
[v1.3.40]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.3.39...v1.3.40
[v1.3.39]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.3.38...v1.3.39
[v1.3.38]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.3.37...v1.3.38
[v1.3.37]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.3.36...v1.3.37
[v1.3.36]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.3.35...v1.3.36
[v1.3.35]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.3.34...v1.3.35
[v1.3.34]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.3.33...v1.3.34
[v1.3.33]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.3.32...v1.3.33
[v1.3.32]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.3.31...v1.3.32
[v1.3.31]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.3.30...v1.3.31
[v1.3.30]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.3.29...v1.3.30
[v1.3.29]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.3.28...v1.3.29
[v1.3.28]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.3.27...v1.3.28
[v1.3.27]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.3.26...v1.3.27
[v1.3.26]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.3.25...v1.3.26
[v1.3.25]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.3.24...v1.3.25
[v1.3.24]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.3.23...v1.3.24
[v1.3.23]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.3.22...v1.3.23
[v1.3.22]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.3.21...v1.3.22
[v1.3.21]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.3.20...v1.3.21
[v1.3.20]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.3.19...v1.3.20
[v1.3.19]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.3.18...v1.3.19
[v1.3.18]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.3.17...v1.3.18
[v1.3.17]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.3.16...v1.3.17
[v1.3.16]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.3.15...v1.3.16
[v1.3.15]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.3.14...v1.3.15
[v1.3.14]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.3.13...v1.3.14
[v1.3.13]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.3.12...v1.3.13
[v1.3.12]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.3.11...v1.3.12
[v1.3.11]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.3.10...v1.3.11
[v1.3.10]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.3.9...v1.3.10
[v1.3.9]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.3.8...v1.3.9
[v1.3.8]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.3.7...v1.3.8
[v1.3.7]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.3.6...v1.3.7
[v1.3.6]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.3.5...v1.3.6
[v1.3.5]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.3.4...v1.3.5
[v1.3.4]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.3.3...v1.3.4
[v1.3.3]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.3.2...v1.3.3
[v1.3.2]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.3.1...v1.3.2
[v1.3.1]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.2.31...v1.3.1
[v1.2.31]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.3.0...v1.2.31
[v1.3.0]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.2.30...v1.3.0
[v1.2.30]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.2.29...v1.2.30
[v1.2.29]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.2.28...v1.2.29
[v1.2.28]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.2.27...v1.2.28
[v1.2.27]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.2.26...v1.2.27
[v1.2.26]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.2.25...v1.2.26
[v1.2.25]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.2.24...v1.2.25
[v1.2.24]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.2.23...v1.2.24
[v1.2.23]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.2.22...v1.2.23
[v1.2.22]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.2.21...v1.2.22
[v1.2.21]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.2.20...v1.2.21
[v1.2.20]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.2.19...v1.2.20
[v1.2.19]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.2.18...v1.2.19
[v1.2.18]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.2.17...v1.2.18
[v1.2.17]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.2.16...v1.2.17
[v1.2.16]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.2.15...v1.2.16
[v1.2.15]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.2.14...v1.2.15
[v1.2.14]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.2.13...v1.2.14
[v1.2.13]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.2.12...v1.2.13
[v1.2.12]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.2.11...v1.2.12
[v1.2.11]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.2.10...v1.2.11
[v1.2.10]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.2.9...v1.2.10
[v1.2.9]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.2.8...v1.2.9
[v1.2.8]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.2.7...v1.2.8
[v1.2.7]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.2.6...v1.2.7
[v1.2.6]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.2.5...v1.2.6
[v1.2.5]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.2.4...v1.2.5
[v1.2.4]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.2.3...v1.2.4
[v1.2.3]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.2.2...v1.2.3
[v1.2.2]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.2.1...v1.2.2
[v1.2.1]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.1.45...v1.2.1
[v1.1.45]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.2.0...v1.1.45
[v1.2.0]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.1.44...v1.2.0
[v1.1.44]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.1.43...v1.1.44
[v1.1.43]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.1.42...v1.1.43
[v1.1.42]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.1.41...v1.1.42
[v1.1.41]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.1.40...v1.1.41
[v1.1.40]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.1.39...v1.1.40
[v1.1.39]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.1.38...v1.1.39
[v1.1.38]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.1.37...v1.1.38
[v1.1.37]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.1.36...v1.1.37
[v1.1.36]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.1.35...v1.1.36
[v1.1.35]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.1.34...v1.1.35
[v1.1.34]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.1.33...v1.1.34
[v1.1.33]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.1.32...v1.1.33
[v1.1.32]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.1.31...v1.1.32
[v1.1.31]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.1.30...v1.1.31
[v1.1.30]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.1.29...v1.1.30
[v1.1.29]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.1.28...v1.1.29
[v1.1.28]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.1.27...v1.1.28
[v1.1.27]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.1.26...v1.1.27
[v1.1.26]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.1.25...v1.1.26
[v1.1.25]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.1.24...v1.1.25
[v1.1.24]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.1.23...v1.1.24
[v1.1.23]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.1.22...v1.1.23
[v1.1.22]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.1.21...v1.1.22
[v1.1.21]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.1.20...v1.1.21
[v1.1.20]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.1.19...v1.1.20
[v1.1.19]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.1.18...v1.1.19
[v1.1.18]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.1.17...v1.1.18
[v1.1.17]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.1.16...v1.1.17
[v1.1.16]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.1.15...v1.1.16
[v1.1.15]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.1.14...v1.1.15
[v1.1.14]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.1.13...v1.1.14
[v1.1.13]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.1.12...v1.1.13
[v1.1.12]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.1.11...v1.1.12
[v1.1.11]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.1.10...v1.1.11
[v1.1.10]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.1.9...v1.1.10
[v1.1.9]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.1.8...v1.1.9
[v1.1.8]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.1.7...v1.1.8
[v1.1.7]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.1.6...v1.1.7
[v1.1.6]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.1.5...v1.1.6
[v1.1.5]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.1.4...v1.1.5
[v1.1.4]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.1.3...v1.1.4
[v1.1.3]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.1.2...v1.1.3
[v1.1.2]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.1.1...v1.1.2
[v1.1.1]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.1.0...v1.1.1
[v1.1.0]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.0.35...v1.1.0
[v1.0.35]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.0.34...v1.0.35
[v1.0.34]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.0.33...v1.0.34
[v1.0.33]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.0.32...v1.0.33
[v1.0.32]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.0.31...v1.0.32
[v1.0.31]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.0.30...v1.0.31
[v1.0.30]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.0.29...v1.0.30
[v1.0.29]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.0.28...v1.0.29
[v1.0.28]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.0.27...v1.0.28
[v1.0.27]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.0.26...v1.0.27
[v1.0.26]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.0.25...v1.0.26
[v1.0.25]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.0.24...v1.0.25
[v1.0.24]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.0.23...v1.0.24
[v1.0.23]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.0.22...v1.0.23
[v1.0.22]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.0.21...v1.0.22
[v1.0.21]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.0.20...v1.0.21
[v1.0.20]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.0.19...v1.0.20
[v1.0.19]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.0.18...v1.0.19
[v1.0.18]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.0.17...v1.0.18
[v1.0.17]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.0.16...v1.0.17
[v1.0.16]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.0.15...v1.0.16
[v1.0.15]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.0.14...v1.0.15
[v1.0.14]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.0.13...v1.0.14
[v1.0.13]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.0.12...v1.0.13
[v1.0.12]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.0.11...v1.0.12
[v1.0.11]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.0.10...v1.0.11
[v1.0.10]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.0.9...v1.0.10
[v1.0.9]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.0.8...v1.0.9
[v1.0.8]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.0.7...v1.0.8
[v1.0.7]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.0.6...v1.0.7
[v1.0.6]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.0.5...v1.0.6
[v1.0.5]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.0.4...v1.0.5
[v1.0.4]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.0.3...v1.0.4
[v1.0.3]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.0.2...v1.0.3
[v1.0.2]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.0.1...v1.0.2
[v1.0.1]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.0.0...v1.0.1
[v1.0.0]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v0.1.40...v1.0.0
[v0.1.40]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v0.1.39...v0.1.40
[v0.1.39]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v0.1.38...v0.1.39
[v0.1.38]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v0.1.37...v0.1.38
[v0.1.37]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v0.1.36...v0.1.37
[v0.1.36]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v0.1.35...v0.1.36
[v0.1.35]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v0.1.34...v0.1.35
[v0.1.34]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v0.1.33...v0.1.34
[v0.1.33]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v0.1.32...v0.1.33
[v0.1.32]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v0.1.31...v0.1.32
[v0.1.31]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v0.1.30...v0.1.31
[v0.1.30]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v0.1.29...v0.1.30
[v0.1.29]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v0.1.28...v0.1.29
[v0.1.28]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v0.1.27...v0.1.28
[v0.1.27]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v0.1.26...v0.1.27
[v0.1.26]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v0.1.25...v0.1.26
[v0.1.25]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v0.1.24...v0.1.25
[v0.1.24]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v0.1.23...v0.1.24
[v0.1.23]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v0.1.22...v0.1.23
[v0.1.22]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v0.1.21...v0.1.22
[v0.1.21]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v0.1.20...v0.1.21
[v0.1.20]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v0.1.19...v0.1.20
[v0.1.19]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v0.1.18...v0.1.19
[v0.1.18]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v0.1.17...v0.1.18
[v0.1.17]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v0.1.16...v0.1.17
[v0.1.16]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v0.1.15...v0.1.16
[v0.1.15]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v0.1.14...v0.1.15
[v0.1.14]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v0.1.13...v0.1.14
[v0.1.13]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v0.1.12...v0.1.13
[v0.1.12]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v0.1.11...v0.1.12
[v0.1.11]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v0.1.10...v0.1.11
[v0.1.10]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v0.1.9...v0.1.10
[v0.1.9]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v0.1.8...v0.1.9
[v0.1.8]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v0.1.7...v0.1.8
[v0.1.7]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v0.1.6...v0.1.7
[v0.1.6]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v0.1.5...v0.1.6
[v0.1.5]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v0.1.4...v0.1.5
[v0.1.4]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v0.1.3...v0.1.4
[v0.1.3]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v0.1.2...v0.1.3
[v0.1.2]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v0.1.1...v0.1.2
[v0.1.1]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v0.1.0...v0.1.1
[v0.1.0]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v0.0.3...v0.1.0
[v0.0.3]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v0.0.2...v0.0.3
[v0.0.2]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v0.0.1...v0.0.2
[v0.0.1]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v0.0.1-alpha1...v0.0.1
