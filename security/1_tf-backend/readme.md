# Terraform - S3 & DynamoDB for Remote State Storage & Locking for Security

## Overview
Use this terraforms configuration files to create the S3 bucket & DynamoDB table needed to use Terraform Remote State Storage & Locking.

## Set Up
- Install terraform >= v0.11.13, use `terraform version` to check
- Ensure you have `make` installed in your system
- Refer to 'readme.md' in the root repository to understand how to set up the configuration file required for this
- Run `make init`
- You should see terraform output and a confirmation prompt to approve the changes
