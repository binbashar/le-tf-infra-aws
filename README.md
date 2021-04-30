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

```shell
╭─    ~/Binbash/repos/Leverage/ref-architecture/le-tf-infra-aws/shared/base-network  on   master !2 ······························································································ ✔  at 08:52:43 
╰─ leverage
[DEBUG] Found config file: /Users/exequielbarrirero/Binbash/repos/Leverage/ref-architecture/le-tf-infra-aws/shared/base-network/build.env
[DEBUG] Found config file: /Users/exequielbarrirero/Binbash/repos/Leverage/ref-architecture/le-tf-infra-aws/build.env
Tasks in build file build.py:
  apply                          Build or change the Terraform infrastructre in this layer. For instance:
                                    > leverage apply
                                    > leverage apply["-auto-approve"]
  decrypt                        Decrypt secrets.tf file.
  destroy                        Destroy terraform infrastructure in this layer.
  encrypt                        Encrypt secrets.dec.tf file.
  format                         Rewrite all Terraform files to meet the canonical format.
  format_check                   Check if Terraform files do not meet the canonical format.
  init                           Initialize Terraform in this layer. For instance:
                                    > leverage init
                                    > leverage init["-reconfigure"]
  output                         Show all terraform output variables of this layer. For instance:
                                    > leverage output
                                    > leverage output["-json"]
  plan                           Generate a Terraform execution plan for this layer.
  shell                          Open a shell into the Terraform container in this layer.
  validate_layout                Validate the layout convention of this Terraform layer.
  version                        Print terraform version.

Powered by Leverage 0.0.18 - A Lightweight Python Build Tool based on Pynt.
```

# Release Management
### CircleCi PR auto-release job

<div align="left">
  <img src="./%40doc/figures/circleci.png" alt="circleci" width="130"/>
</div>

- [**pipeline-job**](https://app.circleci.com/pipelines/github/binbashar/le-tf-infra-aws) (**NOTE:** Will only run after merged PR)
- [**releases**](https://github.com/binbashar/le-tf-infra-aws/releases)
- [**changelog**](https://github.com/binbashar/le-tf-infra-aws/blob/master/CHANGELOG.md)
