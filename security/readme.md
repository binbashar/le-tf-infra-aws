# Terraform Infrastructure - Security

## Pre-requisites

### Makefile
- We rely on Makefiles as a wrapper to run terraform commands that consistently use the same config files.
- You are encouraged to inspect those Makefiles to understand what's going on.

### Terraform
- Install terraform >= v0.11.14
- Run `terraform version` to check

### Remote State
In the `tf-backend` folder you should find all setup scripts or configuration files that need to be run before you can get to work with anything else.

*IMPORTANT:* THIS IS ONLY NEEDED IF THE BACKEND WAS NOT CREATED YET. IF THE BACKEND ALREADY EXISTS YOU JUST USE IT.

### Configuration
- Config files can be found in 'config' folder.
- File `backend.config` contains TF variables that are mainly used to configure TF backend but since `profile` and `region` are defined there, we also use them to inject those values into other TF commands.
- File `main.config` contains TF variables that we inject to TF commands such as plan or apply and which cannot be stored in `backend.config` due to TF restrictions.

### AWS Profile
- File `backend.config` will inject the profile name that TF will use to make changes on AWS.
- Such profile is usually one that relies on another profile to assume a role to get access to each corresponding account.
- Read the following page to understand how to set up a profile to assume a role => https://docs.aws.amazon.com/cli/latest/userguide/cli-roles.html


## Files/Folders Organization
```
    security/
        tf-backend/                 (TF backend initialization files)
            ...
        organization/
            ...                     (Scripts and files used to create organization resources)
        identities/
            ...                     (Terraform files to define IAM resources)
        common/
            ...                     (Terraform files to define Common resources such as aws cloudtrail and config)
```

## Terraform Workflow
- Make sure you read the pre-requisites section
- Get into the folder that you need to work with (e.g. identities)
- Run `make init`
- Make whatever changes you need to make
- Run `make plan` if you only mean to preview those changes
- Run `make apply` if you want to review and likely apply those changes
