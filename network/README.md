# Network firewall & Transit Gateway

You can deploy AWS Network Firewall with and without a Transit Gateway.  

In case you are using AWS Transit Gateway, you need to enable the Network Firewall support in the `transit_gateway' layer`. This will create the necessary TGW route tables and associations to the inspection VPC. Also take into account the TGW layer implements centralized NAT Gateways for all private subnets, therefore you will need first to enable the NAT Gateways in the `network` account.

In order to enable Network Firewall using a Transit Gateway perform the following order:


1. Enable NAT Gateway in the `network` account. Edit the `../network/us-east-1/base-network/network.auto.tfvars' file:

```
# NAT GW
vpc_enable_nat_gateway = true
vpc_single_nat_gateway = true

# VPN Gateways
vpc_enable_vpn_gateway = false
```

Apply the changes.


2. Enable the Network Firewall support in the Transit Gateway layer by editing the `../network/us-east-1/transit-gateway/tgw.auto.tfvars` file:
```
# Transit Gateway
# enable_tgw = false # Set this value in the ../config/common.tfvars

# TGW VPC Attahcments
enable_vpc_attach = {
  network     = true
  shared      = true
  apps-devstg = true
  apps-prd    = true
}

# Network Firewall
enable_network_firewall = true
```

3 Enable the transit gateway by adding the following lines in the `../config/common.tfvars` file:

```
# Networking

# Enable TGW
enable_tgw = true

```
Then apply the changes in the Transit Gateway layer.

4. Finally edit the `network-firewall` layer according to your needs and apply the changes.
