# Secrets Provisioning - Ssh private key file for Provisioner Connections

## Requirements
- Install terraform >= `v0.11.14`
- Install ansible >= `2.4.3.0` (Only if following `/provisioner/readme.md`)
- Install ansible >= 2.4.3.0

## Instructions when using `/provisioner/readme.md`
- Then use the commands in the **Makefile** to work with Terraform in order to apply those changes

1. `$ make init-cmd`
2. `$ make plan` (or `$make plan-detailed` / `make diff`
3. `$ make apply`

### All available `Makefile` commands
```
$ make
Available Commands:
 - apply-cmd          Make terraform apply any changes"
 - destroy            Destroy all resources managed by terraform"
 - diff               Terraform plan with landscape
 - encrypt            ansible-vault encrypt secrets
 - force-unlock       Manually unlock the terraform state, eg: make ARGS="a94b0919-de5b-9b8f-4bdf-f2d7a3d47112" force-unlock
 - format             The terraform fmt is used to rewrite tf conf files to a canonical format and style.
 - init-cmd           Initialize terraform backend, plugins, and modules"
 - plan-detailed      Preview terraform changes with a more detailed output"
 - plan               Preview terraform changes"
 - tf-dir-chmod       run chown in ./.terraform to gran that the docker mounted dir has the right permissions
 - version            Show terraform version
```

## PROVISIONER
- Follow complementary instructions in `/provisioner/readme.md
- Ensure `provisioner/keys/id_rsa` exists and is decrypted (read below)
    - Run `make decrypt` to decrypt the ssh private key file for SSH connection and remote provisioning via Ansible.
    - You'll have to provide the ansible vault password.

## IMPORTANT
- To keep the secrets file decrypted in your local computer is highly discouraged.
- It is even more dangerous to commit/push the secrets file to the remote repository.
- You can run `make encrypt` to encrypt the secrets file before committing/pushing any changes to it.
