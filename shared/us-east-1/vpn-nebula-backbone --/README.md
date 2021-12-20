# Nebula Backbone

## Overview
1. Open `variables.tf`
2. You'll find 4 layer variables, fill the values as you need:
    * `ec2_instances_count`:  Number of instances to be launched
    * `allowed_ips_udp`: List of IPs allowed to access throught the UDP port 3000
    * `allowed_ips_ssh`: List of IPs allowed to access throught the SSH port 22
    * `allowed_ssh_keys`: List of allowed keys to access throught SSH

## Creating a ssh-key to access the EC2 instances
3. Either on a Linux or macOS computer, open a terminal and run:
```
ssh-keygen -t rsa -C "YOUR_EMAIL" -f ~/.ssh/KEY_FILENAME

Generating public/private rsa key pair.
Enter passphrase (empty for no passphrase):
Enter same passphrase again:
Your identification has been saved in ~/.ssh/KEY_FILENAME.
Your public key has been saved in ~/.ssh/KEY_FILENAME.pub.
The key fingerprint is:
SHA256:REDACTED YOUR_EMAIL
The key's randomart image is:
+---[RSA 3072]----+
REDACTED
+----[SHA256]-----+
```

Once created, change the permissions:
```
chmod 600 ~/.ssh/KEY_FILENAME.pub
```

Copy the value of `~/.ssh/KEY_FILENAME.pub` on the variable `allowed_ssh_keys`, for example:

```
variable "allowed_ssh_keys" {
  type        = list(string)
  description = "List of allowed keys to access throught SSH"
  default     = ["ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAB...."]
}
```

# Applying the module
4. Run Terraform
    1. Run `leverage tf init` to initialize this layer (if necessary)
    2. Run `leverage tf plan` to evaluate the changes that will be made
    3. Run `leverage tf apply` to create/update/delete actual resources

5. After the last command succeeds, it should reveal the output of this layer
    Locate the EIPs for each EC2 instance created:
    ```
        Apply complete! Resources: 10 added, 0 changed, 0 destroyed.

            Outputs:

            instance_count = 2
            private_ips = [
            "172.18.6.58",
            "172.18.9.166",
            ]
            public_ips = [
            "54.91.238.249",
            "3.81.31.195",
            ]
    ```

# Testing
6. Grab one of the `public_ips` values and test the ssh connection:

```
ssh ubuntu@54.91.238.249 -i ~/.ssh/KEY_FILENAME.pub
Welcome to Ubuntu 20.04.3 LTS (GNU/Linux 5.11.0-1022-aws x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/advantage

  System information as of Fri Dec 17 17:09:49 UTC 2021

  System load:  0.06              Processes:             110
  Usage of /:   20.4% of 7.69GB   Users logged in:       0
  Memory usage: 5%                IPv4 address for eth0: 172.18.8.126
  Swap usage:   0%


16 updates can be applied immediately.
9 of these updates are standard security updates.
To see these additional updates run: apt list --upgradable


Last login: Fri Dec 17 17:09:32 2021 from 190.195.47.88
To run a command as administrator (user "root"), use "sudo <command>".
See "man sudo_root" for details.

ubuntu@ip-172-18-8-126:~$
```
