# Secrets Provisioning

## Requirements
- Install terraform >= v0.11.7
- Install ansible-vault >= 2.4.3.0

## Instructions
- Ensure secrets.tf is decrypted (read below)
    - Run `make decrypt` to decrypt the secrets file
    - You'll have to provide the vault password
- Modify secrets.tf according to the changes you need to make
- Then use the commands in the Makefile to work with Terraform in order to apply those changes
    - Terraform will fail if the secrets file is encrypted

## IMPORTANT
- To keep the secrets file decrypted in your local computer is highly discouraged
- It is even more dangerous to commit/push the secrets file to the remote repository
- You can run `make encrypt` to encrypt the secrets file before committing/pushing any changes to it
