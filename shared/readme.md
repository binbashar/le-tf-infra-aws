# Terraform Infrastructure

## Pre-requisites

### Makefile
- We rely on Makefiles as a wrapper to run terraform commands

### Terraform
- Install terraform >= v0.11.13
- Run `terraform version` to check

### Remote State
In the `tf-backend` folder you should find all setup scripts or configuration files that need to be run before you can get to work with anything else.

### Configuration
- Get into the 'config' folder
- Run: `cp backend.config.example backend.config`
- Open `backend.config` and set up your AWS profile (this is only to enable every collaborator to define their own profile)
- Hint: read this page to understand how to set up a profile to assume a role => https://docs.aws.amazon.com/cli/latest/userguide/cli-roles.html


## Files/Folders Organization
```
    shared/
        tf-backend/                 (TF backend initialization files)
            ...
        common/                     (Common resources such as IAM, DNS, Network, etc)
            ...
        openvpn/
        kubernetes/
        kubernetes/
        jenkins/
        spinnaker/
        prometheus/
        elastic-kibana/
```

## Terraform Workflow
- Make sure you read the pre-requisites section
- Get into the folder that you need to work with (e.g. identities)
- Run `make init`
- Make whatever changes you need to make
- Run `make plan` if you only mean to preview those changes
- Run `make apply` if you want to review and likely apply those changes
