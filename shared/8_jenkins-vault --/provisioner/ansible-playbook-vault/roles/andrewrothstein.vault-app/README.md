andrewrothstein.vault-app
=========================
[![Build Status](https://travis-ci.org/andrewrothstein/ansible-vault-app.svg?branch=master)](https://travis-ci.org/andrewrothstein/ansible-vault-app)

Role for installing Hashicorp's Vault related applications.

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

```yml
- hosts: servers
  roles:
    - role: andrewrothstein.vault-app
      vault_app: vault
      vault_app_ver: '0.6.5'
      vault_app_checksums:
        darwin_386: sha256:553d65782a853777e5c954bea262bb6f81ac956e5cedb9e03fd88d07a685d90f
        darwin_amd64: sha256:abad5d79c3b81e07405c00997ec5d646e171eaab644a3c35354a03eb2d43c8e9
        freebsd_386: sha256:8b9f91a96705772f10fff6ea1106d8714c06e12b4eda3256ff0dcd435a9accb6
        freebsd_amd64: sha256:df9c8bba6afe118b0fef753f7e3d8a344dfa9a60a008c9bc8d8cc4da60b6b50a
        freebsd_arm: sha256:96358370470d13b5843d021a199305e786809f26392ee4f399429017238b0453
        linux_386: sha256:85dd505f57964add2359798faca0302877b95386a852331bb0e7d43367a41949
        linux_amd64: sha256:c9d414a63e9c4716bc9270d46f0a458f0e9660fd576efb150aede98eec16e23e
        linux_arm: sha256:b97e4da703b93870a614c53431da905029dbb54675f404f6a878536a1852fecf
        netbsd_386: sha256:28daa08f4aff9d1604588184fbecde64b03e7903a33becab39bed68029507b47
        netbsd_amd64: sha256:b1a41b9fed03d90aec5890c5aea09a2a3061932205231aec0a86d798492a844e
        netbsd_arm: sha256:4c1fba2595d32b7ed4bcc5ab586ab71414c26fcd1d37c1bde2b6a8b1899b53c5
        openbsd_386: sha256:ca3ac5925dd5045469430485a22f7d97531bf4a9599424be495e823d24a1d4c3
        openbsd_amd64: sha256:048f0798b9c0cdaa96829049ce629ba7a1ecba87f5df038677b64ecd615b95b3
        solaris_amd64: sha256:a037cfd49e2441982c7cc126b4d5ec0929134399fa955cf4752341c6a6d854d8
        windows_386: sha256:cfc5a9a7beecdf7e7b8424d706b5f39c1d757f329e6ec490fb627d58f147d51e
        windows_amd64: sha256:4ef04179efba3233f1b1fb91c6702a5c7896b1e7d0d7398500a9c0729e81edf7
```

License
-------

MIT

Author Information
------------------

Andrew Rothstein <andrew.rothstein@gmail.com>
