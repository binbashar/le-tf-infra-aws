# ElastiCache Redis Reference Layer

## Overview

This module provisions AWS ElastiCache for Redis clusters.  
**Note:** This module supports only Redis, not Memcached or Valkey. \
You can deploy in two modes:
- **Single Instance Mode:** A single-node, non-sharded Redis cluster.
- **Cluster Mode:** A sharded Redis cluster with configurable replication groups, shards, and nodes.

By default, the module deploys in **Single Instance Mode**.  
To customize variables, edit the `terraform.tfvars` file.

## Cluster Mode

To enable Cluster Mode, set:
```hcl
cluster_mode_enabled           = true
single_instance_mode_enabled   = false
```

- **Shards (Node Groups):** Set `num_node_groups = <number_of_shards>`.
- **Replicas (Nodes) per Shard:** Set `replicas_per_node_group = <number_of_replicas>`.

**Limits:**  
- Maximum 90 nodes per cluster (e.g., 90 shards with 0 replicas, or 15 shards with 5 replicas each).
- Each shard has 1 primary (read/write) node; replicas are read-only.

For more details on sharding and limitations, see the [AWS documentation](https://docs.aws.amazon.com/AmazonElastiCache/latest/dg/Shards.html).

## Multi-AZ and Failover

These features are available only in **Cluster Mode**.

- Enable Multi-AZ: `multi_az_enabled = true`
- Enable Automatic Failover: `automatic_failover_enabled = true`

**Note:** Multi-AZ requires automatic failover to be enabled.  
Both are disabled by default.

## Sizing

- Default node type: `cache.t3.small`
- To change, set the `node_type` variable.

## Single Instance Mode

By default, the module deploys in Single Instance Mode:
```hcl
cluster_mode_enabled           = false
single_instance_mode_enabled   = true
```

## Outputs & Testing

After applying the infrastructure, refer to the `outputs.tf` file for connection details:

- **Port:** Output variable `port`
- **Endpoint:**
  - Single Instance: `cluster_address`
  - Cluster Mode: `replication_group_configuration_endpoint_address`

**To test connectivity:**
```sh
redis-cli --tls -h <endpoint> -p <port> -a '<auth-token>'
```
- Obtain the auth token from your secrets manager.
- If using a VPC, ensure security groups and VPN access are properly configured.