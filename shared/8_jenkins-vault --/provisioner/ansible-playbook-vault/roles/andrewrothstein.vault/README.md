andrewrothstein.vault
=====================
[![Build Status](https://travis-ci.org/andrewrothstein/ansible-vault.svg?branch=master)](https://travis-ci.org/andrewrothstein/ansible-vault)

Install's [Hashicorp's Vault](https://www.vaultproject.io/)

Requirements
------------

See [meta/main.yml](meta/main.yml)

Role Variables
--------------

See [defaults/main.yml](defaults/main.yml)

Dependencies
------------

See [meta/main.yml](meta/main.yml)

Example Playbook
----------------

```
- hosts: servers
  roles:
    - andrewrothstein.vault
```

License
-------

MIT

Author Information
------------------

Andrew Rothstein <andrew.rothstein@gmail.com>
