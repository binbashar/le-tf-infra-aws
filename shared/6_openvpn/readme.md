# Secrets Provisioning - Ssh private key file for Provisioner Connections

## Requirements
- Install terraform >= v0.11.14
- Install ansible >= 2.4.3.0

## Instructions
- Ensure provisioner/keys/id_rsa exists and is decrypted (read below)
    - Run `make decrypt` to decrypt the ssh private key file for
    - You'll have to provide the vault password
- Then use the commands in the Makefile to work with Terraform in order to apply those changes
    - Terraform will fail if the ssh private key file is encrypted

## IMPORTANT
- NEEDS UPDATE
- To keep the secrets file decrypted in your local computer is highly discouraged
- It is even more dangerous to commit/push the secrets file to the remote repository
- You can run `make encrypt` to encrypt the secrets file before committing/pushing any changes to it

## PROVISIONER
- **TODO**