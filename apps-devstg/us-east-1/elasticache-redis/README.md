# Elasticache Redis reference layer

## Overview
This documentation should help you understand the possible variants this layer has. \
Notice this module is helpful to create only elasticache Redis type, not memcache or Valkey. \
This module support both `Single Instance Mode` and `Cluster Mode`. \
In `Cluster Mode`, it will create replication groups, with a shards and a nodes. \
In `Single Instance Mode`, it will create an isolated cluster with a single node and no shards. \
In the `Cluster Mode`, you can manage how many replication groups, shards, and nodes can be created. \
By default this layer will be `Single Instance Mode`.

## MultiAZ and Failover configurations
It only works in `Cluster Mode`. \
This two features can be easily added by setting `multi_az_enabled = true`, and `automatic_failover_enabled = true`. \
If you want to enable MultiAZ, Failover must be enabled as well. \
By default, they are both disabled.

## Sizing
The default size is `cache.t3.small`. \
It can be updated by changing the var `node_type`.

## Cluster Mode
To start this configuration `cluster_mode_enabled = true`, `single_instance_mode_enabled = false` is needed. \
If you want to update the number of shards (or node groups), should set `num_node_groups = <x>`. \
If you want to update the number of replicas (or nodes), should set `replicas_per_node_group = <x>`. \
The limit is 90 nodes. It could be 90 shards with 0 replicas or 15 shards with 5 replicas. (Notice that every shard starts with 1 primary read/write node, and replicas are read-only). \
If you want to check the sharding limitation and possible configurations, can be checked [here](https://docs.aws.amazon.com/AmazonElastiCache/latest/dg/Shards.html).

## Single Instance Mode
By default, it will be a `Single Instance Mode`. \
You should setup the vars `cluster_mode_enabled = false` and `single_instance_mode_enabled = true`.

## How to test it?
Take the endpoint and the port from the output (in the outputs file), and the auth-token from the secret.
redis-cli --tls -h <endpoint> -p <port> -a '<auth-token>'