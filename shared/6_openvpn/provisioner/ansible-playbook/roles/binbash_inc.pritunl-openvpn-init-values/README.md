# Ansible Role: binbash_inc.pritunl-openvpn-init-values

**Print in stdout the initial pritunl setup values.**

- PRITUNL_DB_KEY
- DEFAULT_USER
- DEFAULT_USER

We encourage the user to implement this role as follows, where `print_out_pritunl_setup_secrets` is a variable that will work till you change the admin default admin user and pass from the UI

1st round execution till you update admin user credentials from the UI
```
vars:
    print_out_pritunl_setup_secrets: True

- role: binbash_inc.pritunl-openvpn-init-values
      when: print_out_pritunl_setup_secrets == True
      tags: openvpn-pritunl
```

2nd round execution the flag must be set to `False`
```
vars:
    print_out_pritunl_setup_secrets: False

- role: binbash_inc.pritunl-openvpn-init-values
      when: print_out_pritunl_setup_secrets == True
      tags: openvpn-pritunl
```

if flag it's not set to `False` you'll get the following error:
```
FAILED! => {"changed": true, "cmd": "pritunl default-password | grep 'username: '", "delta": "0:00:01.158679", "end": "2019-03-26 22:58:33.768408", "failed": true, "msg": "non-zero return code", "rc": 1, "start": "2019-03-26 22:58:32.609729", "stderr": "", "stderr_lines": [], "stdout": "", "stdout_lines": []}
```

Since the current output for the command will be an empty string as follows:
```
ubuntu@infra-openvpn:~$ sudo pritunl default-password | grep 'username: '
ubuntu@infra-openvpn:~$
```

**NOTE:** The before error it's actually managed by `ignore_errors: yes` in order to avoid the ansible role to fail if the user forgets to set the flag to `False` after the admin user credentials update.

And the outputs will result as shown below:

```
module.ec2_provisioner_ansible_2.null_resource.ec2-ansible-playbook-tags-vault-pass (local-exec):         "#================================================#",
module.ec2_provisioner_ansible_2.null_resource.ec2-ansible-playbook-tags-vault-pass (local-exec):         "# DEFAULT_USER ",
module.ec2_provisioner_ansible_2.null_resource.ec2-ansible-playbook-tags-vault-pass (local-exec):         "#================================================#"

module.ec2_provisioner_ansible_2.null_resource.ec2-ansible-playbook-tags-vault-pass (local-exec):         "#================================================#",
module.ec2_provisioner_ansible_2.null_resource.ec2-ansible-playbook-tags-vault-pass (local-exec):         "# DEFAULT_USER ",
module.ec2_provisioner_ansible_2.null_resource.ec2-ansible-playbook-tags-vault-pass (local-exec):         "#================================================#"
```