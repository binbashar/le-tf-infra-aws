# ElastiCache for Redis

## Overview
This code can be used as a reference for provisioning AWS ElastiCache for Redis clusters.

## Use Cases
This example showcases a single node cluster, which should be a good fit for low throughput environments.

## Limitations
At the moment, only OSS Redis is supported, not Memcached or Valkey.

## Features
- VPC connectivity
- Encryption at-rest & in-transit
- Authentication via AUTH token

## Roadmap
- Replication
- Data Partitioning
- MultiAZ
- Automated Failover
- Authentication via IAM
- Persistence
- Custom DNS
- Snapshots
- Logging
- Notifications
- Alarms

## Usage
After deploying the infrastructure, refer to the outputs to grab the connection details. You'll need the `endpoint` and `port`.

Now, keep in mind that this setup is configured to be private, but you should be able to connect to it via AWS CloudShell.

However, if you still would like to connect from your machine, you'll need to get VPN access and you'll also need access to the authentication token stored in Secrets Manager. Once you get those, you should be able to connect using the example below:
```sh
redis-cli --tls -h <endpoint> -p <port> -a '<auth-token>'
```

## References
- https://aws.amazon.com/blogs/database/work-with-cluster-mode-on-amazon-elasticache-for-redis/
