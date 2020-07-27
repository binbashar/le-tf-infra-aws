# Change Log

All notable changes to this project will be documented in this file.

<a name="unreleased"></a>
## [Unreleased]



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


[Unreleased]: https://github.com/binbashar/bb-devops-tf-infra-aws/compare/v1.0.9...HEAD
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
