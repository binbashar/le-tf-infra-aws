# Ansible Role: binbash_inc.binbash_inc.aws-ecr-token-login

Role to implement and automate **ecr-token-refresh**, which is a utility for refreshing access tokens to an AWS ECR Registry on a regular interval. It is designed to be used as a sidecar for Spinnaker's Clouddriver service, you can use it from any server though.
It's responsible for refreshing the tokens and writing their values to a file. Ideally, these files would be written to a volume shared between Clouddriver and ecr-token-refresh.

**Reference Links:**
- https://github.com/skuid/ecr-token-refresh
- https://blog.spinnaker.io/using-aws-ecr-with-spinnaker-and-kubernetes-2b2a9bac8bd1


