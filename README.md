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
### CircleCi PR auto-release job

<div align="left">
  <img src="./%40doc/figures/circleci.png" alt="circleci" width="130"/>
</div>

- [**pipeline-job**](https://app.circleci.com/pipelines/github/binbashar/le-tf-infra-aws) (**NOTE:** Will only run after merged PR)
- [**releases**](https://github.com/binbashar/le-tf-infra-aws/releases)
- [**changelog**](https://github.com/binbashar/le-tf-infra-aws/blob/master/CHANGELOG.md)
