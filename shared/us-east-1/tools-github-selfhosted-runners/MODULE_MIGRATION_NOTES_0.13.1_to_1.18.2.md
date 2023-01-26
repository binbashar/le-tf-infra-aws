## Notes on module update

Module is updated from v0.13.1 to v1.18.2.

Despite newer versions exits this was chosen due to is the last one supporting Terraform <1.3.0 and binbash is still heavily using 1.2.7.

### AWS provider

AWS provider is updated from "~> 3.2" to "~> 4.0" to match module requirements.

### KMS Encryption

Encryption settings when calling module is change from this:

```yaml
  # KMS key for encrypting environment variables passed to Lambda
  manage_kms_key = false
  kms_key_id     = data.terraform_remote_state.keys.outputs.aws_kms_key_id
```

to this

```yaml
  # KMS key for encrypting environment variables passed to Lambda
  kms_key_arn     = data.terraform_remote_state.keys.outputs.aws_kms_key_arn
```

### Environment

This parameter is deprecated, changing this:

```yaml
  # For naming, prefix and tagging purposes
  environment = "github-runners"
```

to this

```yaml
  # For naming, prefix and tagging purposes
  prefix = "github-runners"
```
### Instance types

Changed this:

```shell
  # Instance size
  instance_type = "t3.medium"
```

to this

```shell
  # Instance size
  instance_types = ["t3.medium"]
```
### block_device_mappings

Changed this:

```shell
  # Set the block device name for Ubuntu root device
  block_device_mappings = {
    device_name = "/dev/sda1"
    volume_type = "gp2"
    volume_size = 20
  }
```

to this

```shell
  # Set the block device name for Ubuntu root device
  block_device_mappings = [{
    device_name = "/dev/sda1"
    volume_type = "gp2"
    volume_size = 20
  }]
```

### In the user-data.sh

A few changes made here:

```git
diff --git a/shared/us-east-1/tools-github-selfhosted-runners/templates/user-data.sh b/shared/us-east-1/tools-github-selfhosted-runners/templates/user-data.sh
index f5365da6..977f7d84 100644
--- a/shared/us-east-1/tools-github-selfhosted-runners/templates/user-data.sh
+++ b/shared/us-east-1/tools-github-selfhosted-runners/templates/user-data.sh
@@ -1,19 +1,26 @@
 #!/bin/bash -x
 exec > >(tee /var/log/user-data.log | logger -t user-data -s 2>/dev/console) 2>&1

+set +x
+
+%{ if enable_debug_logging }
+set -x
+%{ endif }
+
 ${pre_install}

 # Install AWS CLI
 apt-get update
 DEBIAN_FRONTEND=noninteractive apt-get install -y \
     awscli \
-    jq \
+    build-essential \
     curl \
-    wget \
     git \
+    iptables \
+    jq \
     uidmap \
-    build-essential \
-    unzip
+    unzip \
+    wget

 USER_NAME=runners
 useradd -m -s /bin/bash $USER_NAME
@@ -46,7 +53,7 @@ WantedBy=default.target

 EOF

-echo export XDG_RUNTIME_DIR=/run/user/$USER_ID >>/home/$USER_NAME/.profile
+echo export XDG_RUNTIME_DIR=/run/user/$USER_ID >>/home/$USER_NAME/.bashrc

 systemctl daemon-reload
 systemctl enable user@UID.service
@@ -54,20 +61,22 @@ systemctl start user@UID.service

 curl -fsSL https://get.docker.com/rootless >>/opt/rootless.sh && chmod 755 /opt/rootless.sh
 su -l $USER_NAME -c /opt/rootless.sh
-echo export DOCKER_HOST=unix:///run/user/$USER_ID/docker.sock >>/home/$USER_NAME/.profile
-echo export PATH=/home/$USER_NAME/bin:$PATH >>/home/$USER_NAME/.profile
+echo export DOCKER_HOST=unix:///run/user/$USER_ID/docker.sock >>/home/$USER_NAME/.bashrc
+echo export PATH=/home/$USER_NAME/bin:$PATH >>/home/$USER_NAME/.bashrc

 # Run docker service by default
 loginctl enable-linger $USER_NAME
 su -l $USER_NAME -c "systemctl --user enable docker"

-${install_config_runner}
+${install_runner}

 # config runner for rootless docker
-cd /home/$USER_NAME/actions-runner/
+cd /opt/actions-runner/
 echo DOCKER_HOST=unix:///run/user/$USER_ID/docker.sock >>.env
 echo PATH=/home/$USER_NAME/bin:$PATH >>.env

 ${post_install}

-./svc.sh start
\ No newline at end of file
+cd /opt/actions-runner
+
+${start_runner}

```
### lambdas versions

updated and downloaded

