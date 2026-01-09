# Tools: API Gateway to LB

This layer is aimed to deploy an HTTP Api Gateway proxying traffic to a LB in a private VPC.

It uses a VPC_LINK to reach the private VPC.

The idea is:

* there are multiple applications behind the LB (e.g. in a EKS cluster)
* there are different sites exposing the applications (i.e. a multitenant app being served from different sites)
* under each site, different endpoints will send traffic to the LB with specific data for each application

E.g.:

   site1  -> apigaw_site1 \
                           -> LB -> EKS Cluster (Apps)
   site2  -> apigaw_site2 /

## Steps to deploy

These are the steps:

* define the sites (one or more)
* define the apps (one or more)