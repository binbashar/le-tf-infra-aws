<div align="center">
    <img src="./%40doc/figures/binbash.png"
    alt="binbash" width="250"/>
</div>
<div align="right">
  <img src="./%40doc/figures/binbash-leverage-terraform.png"
  alt="leverage" width="130"/>
</div>

# Leverage Reference Architecture: Terraform AWS Infrastructure

## Overview
This repository contains all Terraform configuration files used to create Binbash Leverage Reference AWS Cloud
Solutions Architecture.

## Documentation
Check out the [Binbash Leverage Reference Architecture Official Documentation](https://leverage.binbash.com.ar).

---

## Binbash Leverage | DevOps Automation Code Library Integration

In order to get the full automated potential of the
[Binbash Leverage DevOps Automation Code Library](https://leverage.binbash.com.ar/how-it-works/code-library/code-library/)  
you should initialize all the necessary helper **Makefiles**.

#### How?
You must execute the `make init-makefiles` command  at the root context

```shell
╭─delivery at delivery-I7567 in ~/terraform/terraform-aws-backup-by-tags on master✔ 2020-10-29
╰─⠠⠵ make
Available Commands:
 - init-makefiles     initialize makefiles

```

### Why?
You'll get all the necessary commands to automatically operate this module via a dockerized approach,
example shown below

```shell
╭─delivery at delivery-ops in ~/le-tf-infra-aws/apps-devstg/base-network on master✔ 2020-10-29
╰─⠠⠵ make
Available Commands:
 - apply               apply-cmd tf-dir-chmod ## Make terraform apply any changes with dockerized binary
 - cost-estimate-plan  ## Terraform plan output compatible with https
 - cost-estimate-state  ## Terraform state output compatible with https
 - decrypt             ## Decrypt secrets.tf via ansible-vault
 - destroy             ## Destroy all resources managed by terraform
 - encrypt             ## Encrypt secrets.dec.tf via ansible-vault
 - force-unlock        ## Manually unlock the terraform state, eg
 - format-check        ## The terraform fmt is used to rewrite tf conf files to a canonical format and style.
 - format              ## The terraform fmt is used to rewrite tf conf files to a canonical format and style.
 - init                init-cmd tf-dir-chmod ## Initialize terraform backend, plugins, and modules
 - init-reconfigure    init-reconfigure-cmd tf-dir-chmod ## Initialize and reconfigure terraform backend, plugins, and modules
 - output              ## Terraform output command is used to extract the value of an output variable from the state file.
 - plan-detailed       ## Preview terraform changes with a more detailed output
 - plan                ## Preview terraform changes
 - shell               ## Initialize terraform backend, plugins, and modules
 - tf-dir-chmod        ## run chown in ./.terraform to gran that the docker mounted dir has the right permissions
 - tflint-deep         ## TFLint is a Terraform linter for detecting errors that can not be detected by terraform plan (tf0.12 > 0.10.x).
 - tflint              ## TFLint is a Terraform linter for detecting errors that can not be detected by terraform plan (tf0.12 > 0.10.x).
 - validate-tf-layout  ## Validate Terraform layout to make sure it's set up properly
 - version             ## Show terraform version

```

```shell
╭─delivery at delivery-ops in ~/le-tf-infra-aws/apps-devstg/base-network on master✔ 2020-10-29
╰─⠠⠵ make init
docker run --rm -v ~/le-tf-infra-aws/apps-devstg/base-network:"/go/src/project/":rw \
    -v ~/le-tf-infra-aws/apps-devstg/config:/config \
    -v ~/le-tf-infra-aws/config/common.config:/common-config/common.config \
    -v ~/.ssh:/root/.ssh -v ~/.gitconfig:/etc/gitconfig \
    -v ~/.aws/bb:/root/.aws/bb \
    -e AWS_SHARED_CREDENTIALS_FILE=/root/.aws/bb/credentials \
    -e AWS_CONFIG_FILE=/root/.aws/bb/config \
    --entrypoint=/bin/terraform \
    -w "/go/src/project/" \
    -it binbash/terraform-awscli-slim:0.13.2 init \
    -backend-config=/config/backend.config
Initializing modules...

Initializing the backend...

Initializing provider plugins...
- terraform.io/builtin/terraform is built in to Terraform
- Using previously-installed hashicorp/aws v3.9.0

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
LOCAL_OS_USER_ID: 1000
LOCAL_OS_GROUP_ID: 1000
sudo chown -R 1000:1000 ./.terraform

```

# Release Management
### CircleCi PR auto-release job

<div align="left">
  <img src="./%40doc/figures/circleci.png" alt="circleci" width="130"/>
</div>

- [**pipeline-job**](https://app.circleci.com/pipelines/github/binbashar/le-tf-infra-aws) (**NOTE:** Will only run after merged PR)
- [**releases**](https://github.com/binbashar/le-tf-infra-aws/releases)
- [**changelog**](https://github.com/binbashar/le-tf-infra-aws/blob/master/CHANGELOG.md)
