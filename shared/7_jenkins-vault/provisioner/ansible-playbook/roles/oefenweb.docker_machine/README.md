## docker-machine

[![Build Status](https://travis-ci.org/Oefenweb/ansible-docker-machine.svg?branch=master)](https://travis-ci.org/Oefenweb/ansible-docker-machine) [![Ansible Galaxy](http://img.shields.io/badge/ansible--galaxy-docker--machine-blue.svg)](https://galaxy.ansible.com/Oefenweb/docker-machine/)

Set up (the latest or a specific version of) [Docker Machine](https://docs.docker.com/machine) in Debian-like systems.

#### Requirements

None

#### Variables

* `docker_machine_version` [default: `v0.16.1`]: Version to install
* `docker_machine_install_prefix` [default: `/usr/local/bin`]: Install prefix
* `docker_machine_download_url` [default: `https://github.com`]: Download url

## Dependencies

None

## Recommended

* `ansible-docker` ([see](https://github.com/Oefenweb/ansible-docker))
* `ansible-docker-compose` ([see](https://github.com/Oefenweb/ansible-docker-compose))

#### Example

```yaml
---
- hosts: all
  roles:
    - docker-machine
```

#### License

MIT

#### Author Information

Mischa ter Smitten

#### Feedback, bug-reports, requests, ...

Are [welcome](https://github.com/Oefenweb/ansible-docker-machine/issues)!
