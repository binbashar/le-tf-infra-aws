#!/bin/bash +x

apt-get update

%{ for pub_key in allowed_ssh_keys ~}
    echo "Adding key ${pub_key} to authorized_keys...."
    echo "${pub_key}" >> "/home/ubuntu/.ssh/authorized_keys"
%{ endfor }

chown ubuntu:ubuntu /home/ubuntu/.ssh/authorized_keys
chmod -R go-rx /home/ubuntu/.ssh
echo "DONE"