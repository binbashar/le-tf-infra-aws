# Network firewall & Transit Gateway

You can deploy AWS Network Firewall with and without a Transit Gateway.  

In case you are using AWS Transit Gateway, you need to enable the Network Firewall support in the `transit_gateway' layer`. This will create the necessary TGW route tables and associations to the inspection VPC. Also take into account the TGW layer implements centralized NAT Gateways for all private subnets, therefore you will need first to enable the NAT Gateways in the `network` account.

In order to enable Network Firewall using a Transit Gateway perform the following order:


1. Enable NAT Gateway in the `network` account. Edit the `../network/us-east-1/base-network/network.auto.tfvars` file:

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

3. Enable the transit gateway by adding the following lines in the `../config/common.tfvars` file:

```
# Networking

# Enable TGW
enable_tgw = true

```
Then apply the changes in the Transit Gateway layer.

4. Finally edit the `network-firewall` layer according to your needs and apply the changes.


# Multi Region Transit Gateways + Network Firewall

In order to deploy a Transit Gateway and a Network Firewall in a secondary region follow these steps:

1. In the secondary region deploy the Transit Gateway and the Network Firewall as done in the primary region.
2. Then go to the Transit Gateway layer in the primary region to deploy the Transit Gateways peering defined in the `../network/us-east-1/base-network/tgw-peerings.tf` file. This will create a peering request to the Transit gateway in the secondary region.
3. Go to the Transit Gateway layer in the secondary region to accept the request as defined in the `../network/us-east-2/base-network/tgw-accepters.tf` file.

# Toggling VPC Peerings / Transit Gateway

## VPC Peerings -> Transit Gateway

When VPC peerings are deployed you need to follow this workflow to toggle the Transit Gateway:

1. Enable the transit gateway by setting  `tgw = true` in the `../config/common.tfvars` file.
2. Then go to any network sublayer with a `vpc_peerings.tf` file (`shared`, `apps-*/base-network`) and apply the changes using leverage cli. This will destroy all VPC peerings.
3. Go to the `network/transing-gateway` layer and apply the changes using leverage cli in order to create all TGW resources.
4. In every network layer definition (`apps-devstg/network`, `apps-devstg/k8s-eks-demoapps/network`, etc)  apply the changes using leverage cli to create the needed routes to the TGW in each VPC / subnet.
5. In case Network Firewall is required you have to go to the `network/network-firewall` layer and set `enabled_network_firewall=true` in the `network.auto.tfvars`  and apply he changes using leverage cli. This will create the inspection VPC, subnets, route tables and the Network Firewall per sé. Then you have to go to the `network/transit-gatewway` layer and set `enabled_network_firewall = true` in the `tgw.auto.tfvars` file and apply this changes to create the TGW inspection route table and update the TGW associations.

## VPC Peerings -> Transit Gateway multi region

1. Create the TGW for each region (and their Network Firewalls if apply) as explained before, validate that each one works.
2. Enable the transit gateway multi-region support by setting  `tgw_multi_region = true` in the `../config/common.tfvars` file.
3. In the main region go to the the `network/transit-gateway` layer and apply changes using leverage cli. This will create a TGW peering request to the secondary region.
4. Go to `network/transit-gateway` layer of the secondary region and apply changes using leverage cli to accept the request.
5. In case more TGWs are needed use the `tgw-peerings.tf` and  `tgw-peerings-acccepters.tf` files of the primary and secondary regions respectively as a template.

## Transit Gateway -> VPC Peerings

When TGWs are deployed you need to follow this workflow to toggle VPC peerings:

1. Disable the transit gateway by setting  `tgw = false` in the `../config/common.tfvars` file.
2. Go to the `network/transit-gateway` layer and apply  changes so that all TGW resources are destroyed.
3. If  NEtwork Firewall was enabled, set `enabled_network_firewall=false` in the n`etwork/network-firewal/network.auto.tfvar` file and destroy the network firewall resources as well by applying the changes in that layer.
4. For each sublayers where there is a network definition, for example `apps-devstg/base-network/`, `apps-devstg/k8s-eks-demoapps/network/` , etc, apply the changes using leverage cli to remove the routes that aimed to the TGW. These network sublayers are where the `vpc_peerings.tf` files are located, so when applying the VPC peerings will be created again.
