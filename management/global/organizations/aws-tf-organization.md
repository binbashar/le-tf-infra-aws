## AWS Terraform Management

### Update AWS Organization features
1. Go to `management/global/organizations`.
2. Edit `organization.tf` to enable/disable Organization features
3. Or edit the `policies_scp.tf` file to add/remove/update Service Control Policies.
4. Finally, run the Terraform workflow to apply the actual changes.

### Add/remove AWS accounts
1. Go to `management/global/organizations`.
2. Edit `locals.tf` to add/remove accounts from the local `accounts` variable.
3. Finally, run the [Terraform workflow](#terraform-workflow) to apply the actual changes.
4. Add the new account to `config/common.tfvars`.
5. From here, you may very likely want to create the initial directory structure for this new account *as explained right below*.

### Add/remove/update AWS Organization Service Control Policies
1. Go to `management/global/organizations`.
2. Edit the `policies_scp.tf` file to add/remove/update Service Control Policies.
3. Finally, run the [Terraform workflow](#terraform-workflow) to initialize and apply this layer.

### Add/remove AWS IAM user accounts
For instance, to remove a user from the security account you would need to make the following steps:
1. Go to `security/global/base-identities`
2. Remove the user from the users list in `locals.tf` file.
3. Also remove it from the corresponding groups in `groups.tf` file.
4. Remove output references from `outputs.tf` file.
5. Delete the corresponding GPG key from the `keys` subdirectory.
6. Finally, run the [Terraform workflow](#terraform-workflow) to initialize and apply this layer.

And to remove a user from the security account you can follow the same steps but should instead go to this directory: `management/global/base-identities`

### Create the initial directory structure for a new account
As an example, we will set up the `apps-prd` account by using the `apps-devstg` as a source reference code:
1. Ensure you are at the root of this repository
2. Create the initial directory structure for the new account:
    ```
    mkdir -p apps-prd/global
    mkdir -p apps-prd/us-east-1
    ```
3. Set up the config files:
    1. Create a config files for this account: `cp -r apps-devstg/config apps-prd/config`
    2. Open `apps-prd/config/backend.tfvars` and replace any occurrences of `devstg` with `prd`
    3. Do the same with `apps-prd/config/account.tfvars`
    4. Open up `apps-prd/config/backend.tfvars` again and replace this:
        ```
        profile = "bb-apps-prd-devops"
        ```
        with this:
        ```
        profile = "bb-apps-prd-oaar"
        ```
    5. In the step above, we are switching to the OAAR (OrganizationalAccountAccessRole) role because we are working with a brand new account that is empty, so, the only way to access it programmatically is through the OAAR role.
    6. Now it's time to configure your OAAR credentials (if haven't already done so). For that you can follow the steps in [this section](https://leverage.binbash.com.ar/first-steps/management-account/#update-the-bootstrap-credentials) of the official documentation.
4. Create the `base-tf-backend` layer:
    1. Copy the layer from an existing one: `cp -r apps-devstg/us-east-1/base-tf-backend apps-prd/us-east-1/base-tf-backend`
    2. Go to the `apps-prd/us-east-1/base-tf-backend` directory and open the `config.tf` file. Comment this block:
        ```
        backend "s3" {
        key = "apps-devstg/tf-backend/terraform.tfstate"
        }
        ```
    3. Now run the [Terraform workflow](#terraform-workflow) to initialize and
       apply this layer.  (You may need to pass the `--skip-validation` flag to
       `leverage tf init`.)
    4. Open the `config.tf` file again and un-comment the block you commented before but first make sure you replace any occurrences of `devstg` with `prd`
    5. Now run `leverage tf init`. Terraform should detect that you are trying to move a local state to a remote state and should prompt you for confirmation.
5. Before moving on, go back to the root of this repository
6. Now let's set up the base identities for the new account:
    1. Create this layer from an existing one: `cp -r apps-devstg/global/base-identities apps-prd/global/base-identities`
    2. Go to the `apps-prd/global/base-identities` directory and open the `config.tf` file. Replace any occurrences of `devstg` with `prd`
    3. Now run `leverage tf init`
    4. Import the OAAR role: `leverage terraform import module.iam_assumable_role_oaar.aws_iam_role.this OrganizationAccountAccessRole`
    5. Now run `leverage tf apply`

7. It's time for add a `security-base`  
    1. Create this layer from an existing one: `cp -r apps-devstg/us-east-1/security-base apps-prd/us-east-1/security-base`
    2. Go to the `apps-prd/us-east-1/security-base` directory and open the `config.tf` file. Replace any occurrences of `devstg` with `prd`
    3. Now run `leverage tf init`
    5. Now run `leverage tf apply`

8. Use the DevOps role instead of the OAAR role:
    1. Open up `apps-prd/config/backend.tfvars` again and replace this:
        ```
        profile = "bb-apps-prd-oaar"
        ```
        with this:
        ```
        profile = "bb-apps-prd-devops"
        ```
    2. This is needed because we only want to use the OAAR role for exceptional cases, not on daily basis.
    3. Now, let's configure your DevOps credentials (if you haven't already done so).
        1. Log into your security account, create programmatic access keys, and enable MFA.
        2. Then run: `leverage credentials configure --fetch-mfa-device --type SECURITY`
        3. The command above should prompt for your programmatic keys and, with those, it should be able to configure you AWS config and credentials files appropriately.
9.  That should be it. At this point you should have the following:
    1. A brand-new AWS account
    2. Configuration files that are needed for any layer that is created under this account
    3. A Terraform State Backend for this new account
    4. Roles and policies (base identities) that are necessary to access the new account
