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

## Getting Started

In order to get the full automated potential of the
[Binbash Leverage DevOps Automation Code Library](https://leverage.binbash.com.ar/how-it-works/code-library/code-library/)  
you should follow the steps below:

1. [Install](https://leverage.binbash.com.ar/first-steps/local-setup/) and use the `leverage cli`
2. Update your [configuration files](https://leverage.binbash.com.ar/user-guide/base-configuration/repo-le-tf-infra-aws/#configuration)
3. Review and assure you meet all the Terraform AWS pre-requisites 
   1. AWS Credentials (Including your MFA setup)
      1. Configure your
          1. [Web Console](https://leverage.binbash.com.ar/first-steps/post-deployment/#get-the-temporary-password-to-access-aws-console)
          2. [Programmatic Keys](https://leverage.binbash.com.ar/first-steps/post-deployment/#configure-the-new-credentials)
              - Types:
                  1. [management account creds](https://leverage.binbash.com.ar/user-guide/features/identities/credentials/#management-credentials)
                  2. [security account creds](https://leverage.binbash.com.ar/user-guide/features/identities/credentials/#security-credentials)
    2. [Initialize your accounts Terraform State Backend](https://leverage.binbash.com.ar/user-guide/base-workflow/repo-le-tf-infra-aws-tf-state/)

4. Follow the [standard `leverage cli` workflow](https://leverage.binbash.com.ar/user-guide/base-workflow/repo-le-tf-infra/) 
    1. Get into the folder that you need to work with (e.g. [`/security/global/base-identities`](https://github.com/binbashar/le-tf-infra-aws/tree/master/security/global/base-identities) )
    2. Run `leverage terraform init` 
    3. Make whatever changes you need to make
    4. Run `leverage terraform plan` (if you only mean to preview those changes)
    5. Run `leverage terraform apply` (if you want to review and likely apply those changes)
    6. Repeat for any desired Reference Architecture layer 

### Consideration

The `backend.tfvars` will inject the profile name with the necessary permissions that Terraform will 
use to make changes on AWS.
* Such profile is usually one that relies on another profile to assume a role to get access to 
  each corresponding account [( AWS IAM: users, groups, roles & policies )](https://leverage.binbash.com.ar/how-it-works/features/identities/identities/)
* Read the following [AWS page doc](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-role.html) 
  to understand how to set up a profile to assume a role

#### How?
Install the `leverage` cli following its [instructions](https://github.com/binbashar/leverage)

### Why?
You'll get all the necessary commands to automatically operate this module via a dockerized approach,
example shown below

#### Project context commands
```shell
╭─    ~/Binbash/repos/Leverage/ref-architecture/le-tf-infra-aws/shared/base-network  on   master !2 ······························································································ ✔  at 08:52:43 
╰─ leverage

Usage: leverage [OPTIONS] COMMAND [ARGS]...

  Leverage Reference Architecture projects command-line tool.

Options:
  -f, --filename TEXT  Name of the build file containing the tasks
                       definitions.  [default: build.py]
  -l, --list-tasks     List available tasks to run.
  -v, --verbose        Increase output verbosity.
  --version            Show the version and exit.
  -h, --help           Show this message and exit.

Commands:
  credentials  Manage AWS cli credentials.
  project      Manage a Leverage project.
  run          Perform specified task(s) and all of its dependencies.
  terraform    Run Terraform commands in a custom containerized...
  tf           Run Terraform commands in a custom containerized...
```

#### Layer context Terraform commands
```shell
╭─    ~/B/r/L/ref-architecture/le-tf-infra-aws  on   feature/guarduty-update · ✔  at 12:13:36 
╰─ leverage terraform
Usage: leverage terraform [OPTIONS] COMMAND [ARGS]...

  Run Terraform commands in a custom containerized environment that provides
  extra functionality when interacting with your cloud provider such as
  handling multi factor authentication for you. All terraform subcommands that
  receive extra args will pass the given strings as is to their corresponding
  Terraform counterparts in the container. For example as in `leverage
  terraform apply -auto-approve` or `leverage terraform init -reconfigure`

Options:
  -h, --help  Show this message and exit.

Commands:
  apply     Build or change the infrastructure in this layer.
  aws       Run a command in AWS cli.
  destroy   Destroy infrastructure in this layer.
  format    Check if all files meet the canonical format and rewrite them...
  import    Import a resource.
  init      Initialize this layer.
  output    Show all output variables of this layer.
  plan      Generate an execution plan for this layer.
  shell     Open a shell into the Terraform container in this layer.
  validate  Validate code of the current directory.
  version   Print version.
```

# Release Management
## [**Reference Architecture | Releases**](https://github.com/binbashar/le-tf-infra-aws/releases)
