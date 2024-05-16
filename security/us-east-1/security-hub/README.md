# AWS Security Hub Configuration

This directory contains the Terraform configuration files for setting up AWS Security Hub in the `us-east-1` region.

## Overview

AWS Security Hub provides a comprehensive view of your high-priority security alerts and compliance status across your AWS accounts. This configuration enables the default security standards: AWS Foundational Security Best Practices v1.0.0 and CIS AWS Foundations Benchmark v1.2.0.

## Configuration

- `config.tf`: This file contains the AWS provider settings and the backend configuration for Terraform.
- `security_hub.tf`: This file contains the resource configuration for AWS Security Hub.

    - `enable_default_standards`: Specifies whether to enable the default security standards.
    - `auto_enable_controls`: This property determines whether new security controls are automatically enabled as they become available
    - `control_finding_generator`: Specifies whether the calling account has consolidated control findings turned on. `SECURITY_CONTROL` or `STANDARD_CONTROL`

## Usage

To manage this layer, follow these steps:

1. Move into the `le-tf-infra-aws/security/us-east-1/security-hub` directory:

    ```bash
    cd le-tf-infra-aws/security/us-east-1/security-hub
    ```

1. Initialize the Terraform configuration:

    ```bash
    leverage terraform init --skip-validation
    ```

1. Plan the infrastructure changes:

    ```bash
    leverage terraform plan
    ```

1. Apply the infrastructure changes:

    ```bash
    leverage terraform apply
    ```

1. Verify that the security hub layer has been provisioned successfully.
