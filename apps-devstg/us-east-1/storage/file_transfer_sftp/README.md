# SFTP File Sharing using AWS Transfer

## Instructions
1. Open `terraform.tfvars`
2. Locate the line where the `customers` list is
3. Add an entry to that list in order to onboard a new customer / user / project
    1. For instance, "jane.doe" and "john.doe" can be added to the list as follows:
        ```
        customers = [
          jane = {
            username       = "jane.doe",
            ssh_public_key = "ssh-rsa QQQQQQQWWWWWWWWWWWEEEEEEEEEERRRR..."
          },
          john = {
            username       = "john.doe",
            ssh_public_key = "ssh-rsa AAAAAAAABBBBBBBBBBCCCCCCCCCCDDDD..."
          },
          #EOL#
        ]
        ```
        IMPORTANT: Customers need to provide the SSH public key that we need to add to the list and they must ensure they keep and use the corresponding private key in a secure way.
    2. Entries on this list determine names of AWS resource that will be created
       (e.g. S3 bucket name, IAM user/policy/role name). Because of that, the only characters allowed
       are: lowercase letters, numbers, dots (.), and hyphens (-).
    3. The `#EOL#` mark at the end of the list is not really necessary but we left it there as it could help us with making this process more automated down the road.
       The idea is to replace that mark using simple bash commands such as this
       one: `cat terraform.tfvars | gsed 's/#EOL#/\"mike\",\n  #EOL#/'`
4. Run Terraform
    1. Run `leverage tf init` to initialize this layer (if necessary)
    2. Run `leverage tf plan` to evaluate the changes that will be made
    3. Run `leverage tf apply` to create/update/delete actual resources
5. After the last command succeeds, check the outputs of this layer:
    1. You can share the `server_custom_endpoint` or the `server_endpoint` so that your customers can connect to the server.
    2. From `customers_usernames` you can find the username that your customers will need to use to log in to the server. They will also need the SSH private key that matches the public key they provided to for adding it to the terraform.tfvars file in step 3.


## Notes

### Generating customer keys only for testing
Use something like this: `ssh-keygen -P "" -m PEM -f jane.doe`
But notice how we are not using a passphrase in that command. That's why this is only for testing.

## Testing connectivity to the server
Use netcat like this: `nc -z s-1234567890.server.transfer.us-east-1.amazonaws.com 22`
Or use a command-line sftp client like this one:
`sftp -i /path/to/jane-doe-private-key jane.doe@s-1234567890.server.transfer.us-east-1.amazonaws.com`

## Using a custom host key for the server
You can pass a custom host key to the server by using the `server_host_key` variable.
Here's an example of how to generate such key: `ssh-keygen -N "" -m PEM -f my-new-server-key`
