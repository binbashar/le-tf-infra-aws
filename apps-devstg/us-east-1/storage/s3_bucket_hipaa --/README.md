# S3 HIPAA buckets for File Sharing

## Instructions
1. Open `terraform.tfvars
2. Locate the line where the `customers` list is
3. Add an entry to that list in order to onboard a new customer / user / project
    1. For instance, "jane.doe" and "john.doe" can be added to the list as follows:
        ```
        customers = [
          "jane.doe",
          "john.doe",
          #EOL#
        ]
        ```
    2. Entries on this list determine names of AWS resource that will be created
       (e.g. S3 bucket name, IAM user/policy/role name). Because of that, the only characters allowed
       are: lowercase letters, numbers, dots (.), and hyphens (-).
    3. The `#EOL#` mark at the end of the list could help with making this process more automated.
       The idea is to replace that mark using simple bash commands such as this
       one: `cat terraform.tfvars | gsed 's/#EOL#/\"mike\",\n  #EOL#/'`
4. Run Terraform
    1. Run `leverage tf init` to initialize this layer (if necessary)
    2. Run `leverage tf plan` to evaluate the changes that will be made
    3. Run `leverage tf apply` to create/update/delete actual resources
5. After the last command succeeds, it should reveal the output of this layer
    1. Locate the user that was created; the one that matches the entry you added to the list
    2. Grab the AWS IAM programmatic credentials and the AWS IAM role that matches
       your entry. You will need *securely* share these with the actual customer
    3. Example Output:
      ```
      Outputs:

      customers_buckets = {
        "jane.doe" = "bb-cfs-customer-jane.doe-files"
        "john.doe" = "bb-cfs-customer-john.doe-files"
      }
      customers_iam_access_key_encrypted_secrets = {
        "jane.doe" = "wcBMA9xZo1W3poDtAQgAScZT/1y3Tm+Dc/o7Dk1iCNNqm1MzYF2eKFn6VLzZaoPgDouifmLhSiGRlpcw2H+FfPrjovXmr/OnjZebx6b6+9LuIH/FbVVeQMnx0VOVDGy/WWdWpLPbJgqgQ0k4vAE83/CaCQlKKwMbm1lgmX4+DgqVjZaQcz5NYU00o7zAEdyShfTB4QPaaI/05CyGJtj3enJ4oAJIymTelNYb6/Xy2DguLvOwxA5CmUTqUYfqp78TILlZ9J4LFNrE67KGkKR0lRF/rPvY0wPyyj5641ocElooyMmfc4G36BFKuX5dzlum+yee63UlHtoTyddofV0e4PrT9Cu2QhERRySWao8DH9LgAeSfdfmLW0YnEkE8mCT3LZy14ZSa4Cngu+G0p+B94hpRHC/gauV+92B+ggeXdTuxg52oNfpjlapJ6fkD6NJhJYxb8fLUzeD049peQlVBDuhS4JjkeRRziIt9AZmdYaUGAzRdZOIJusUV4cRNAA=="
        "john.doe" = "wcBMA9xZo1W3poDtAQgAMtLPpafkawjLDndYahb5LKDzAHPa1X0hw3zDmPm7NEl7XP1QLJQ65psDDSUKacwoIcEaJ/hH4cMbQ186dojvubj+8LsnkvUKyWNE+m1Wfn2a18vH+//L8KsWbEG9342riwi/EKVJGsHzhD0JeXyHi5jNdWcGyTsuAJqKtt3wjrHxKHFj7FfdJyJ7r9FTR2MikBB75u3iXLIEx82U8Gdq9+nFmQxs6kkzNYkGDwYP2vw77etE4BGB7Bvki1Vd4PpMWA/4nxOjwjuxQvn5pwm3S7o8NXWe6KBZdj2iz2bmmLZWxwbqelFq+hZIGXHOloCpA7qZSnHbFsrpia7YxHJMEtLgAeRLK87tkyUTnc5Adwd9p6pu4Si14MXg5+EMA+CN4qvdlVDgV+Whl7hRJ4dmopr5xPQeUQcNSZFgvH2mNv30CiSzkpdVZOAF41BShx7ZvBQc4PXkSPyWU/ydwFw3PmJaAjkmBeKnDYXL4UbfAA=="
      }
      customers_iam_access_key_ids = {
        "jane.doe" = "AKIAXXXXXXXXXXXXXXXX"
        "john.doe" = "AKIAXXXXXXXXXXXXXXXX"
      }
      customers_roles = {
        "jane.doe" = "arn:aws:iam::XXXXXXXXXXXX:role/cfs-role-jane.doe"
        "john.doe" = "arn:aws:iam::XXXXXXXXXXXX:role/cfs-role-john.doe"
      }
      customers_usernames = {
        "jane.doe" = "cfs-user-jane.doe"
        "john.doe" = "cfs-user-john.doe"
      }
      ```

6. Setting up credentials
   1. 💻 🔑 **Method 1:** The bucket is created in the `binbash-apps-devstg` account, so in order to list the
      bucket you would need to assume a role that is also in `binbash-apps-devstg` account.
      The role is also an output of the layer.

      So to test access with a bucket list command
      `aws s3 ls s3://bb-cfs-customer-jane.doe-files --profile bb-apps-devstg-jane.doe` and to make
      it work you would have to create a corresponding profile in the `./aws/bb/config` file

      ```
      [profile bb-apps-devstg-jane.doe]
      output=json
      region=us-east-1
      role_arn=arn:aws:iam::XXXXXXXXXXXX:role/cfs-role-jane.doe
      source_profile=bb-security-jane.doe
      ```

      and also put the programmatic credentials of the customer in the `./aws/bb/credentials`  file,

      ```
      [bb-security-jane.doe]
      aws_access_key_id=[EDITED]
      aws_secret_access_key=[EDITED]
      region=us-east-1
      output=json
      ```

      similar to how the [Leverage cli is configured](https://leverage.binbash.com.ar/user-guide/features/identities/credentials/).

    2. 💻 🔑 **Method 2** : Another way to test the credentials without setting those profiles
       would be:

      ```
      export AWS_ACCESS_KEY_ID=[EDITED]
      export AWS_SECRET_ACCESS_KEY=[EDITED]
      export AWS_DEFAULT_REGION=us-east-1
      aws sts assume-role \
          --role-arn arn:aws:iam::XXXXXXXXXXXX:role/cfs-role-jane.doe \
          --role-session-name any-session-name-here \
          --duration-seconds 3600
      ```

      This command should output temporary credentials that you can then use to list the bucket.
      Then on another terminal tab you could run:

      ```
      export AWS_ACCESS_KEY_ID=[FROM_THE_OUTPUT_OF_ASSUME_ROLE_CMD]
      export AWS_SECRET_ACCESS_KEY=[FROM_THE_OUTPUT_OF_ASSUME_ROLE_CMD]
      export AWS_SESSION_TOKEN=[FROM_THE_OUTPUT_OF_ASSUME_ROLE_CMD]
      aws s3 ls s3://bb-cfs-customer-jane.doe-files
      ```

      📒 **NOTE:** all of this is actually simplified by the use of the profiles in the `~/.aws/bb/config`
      & `~/.aws/bb/credentials` files as described in **Method 1**

# About the GPG key being used
There is a GPG key under `keys/machine.s3.demo` which is used to encrypt the programmatic
access key secret that is generated by this layer. Same approach we use for `/security/global/base-identities`
