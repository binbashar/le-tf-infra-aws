# A little help with PGP keys

## Create a key pair
- NOTE: the user for whom this account is being created needs to do this
- Install `gpg`
- Run `gpg --version` to confirm
- Run `gpg --gen-key` and provide "Your Name" and "Your Email" as instructed -- you must also provide a passphrase
- Run `gpg --list-keys` to check that your key was generated

## Delete a key pair
- Run `gpg --list-keys` to check your key id
- Run `gpg --delete-secret-keys "Your Name"` to delete your private gpg key
- Run `gpg --delete-key "Your Name"` to delete your public gpg key

## Export your public key
- NOTE: the user must have created a key pair before doing this
- Run `gpg --export "Your Name" | base64`
- Now the user can share her/his public key for creating her/his account

## Decrypt your encrypted password
1. The user should copy the encrypted password from whatever media it was provided to her/him
2. Run `echo "YOUR ENCRYPTED STRING PASSWORD HERE" | base64 --decode > a_file_with_your_pass`
3. Run `gpg --decrypt a_file_with_your_pass` to effectively decrypt your pass using your gpg key and its passphrase
4. If all went well, the decrypted password should be there