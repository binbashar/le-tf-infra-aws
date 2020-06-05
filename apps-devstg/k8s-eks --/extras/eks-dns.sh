#!/bin/bash

#
# DNS resolution for EKS Private Endpoints
# ref solution: http://www.studytrails.com/devops/kubernetes/local-dns-resolution-for-eks-with-private-endpoint/
# github open issue: https://github.com/aws/containers-roadmap/issues/221
#

#
# eg: bash ~/.aws/eks-dns.sh bb-dev-eks-BedMAWiB bb-apps-devstg-devops
#
clusterName=$1
awsProfile=$2

#
# Get EKS ip addrs
#
ips=`aws ec2 describe-network-interfaces --profile $awsProfile \
--filters Name=description,Values="Amazon EKS $clusterName" \
| grep "PrivateIpAddress\"" | cut -d ":" -f 2 |  sed 's/[*",]//g' | sed 's/^\s*//'| uniq`

echo "#-----------------------------------------------------------------------#"
echo "# EKS Private IP Addresses:                                              "
echo $ips
echo "#-----------------------------------------------------------------------#"
echo ""

#
# Get EKS API endpoint
#
endpoint=`aws eks describe-cluster --profile $awsProfile --name $clusterName \
| grep endpoint\" | cut -d ":" -f 3 | sed 's/[\/,"]//g'`

echo "#-----------------------------------------------------------------------#"
echo "# EKS Private Endpoint                                                   "
echo $endpoint
echo "#-----------------------------------------------------------------------#"
echo ""

IFS=$'\n'
#
# Create backup of /etc/hosts
#
sudo cp /etc/hosts /etc/hosts.backup.$(date +%Y-%m-%d)

#
# Clean old EKS endpoint entries from /etc/hots
#
if grep -q $endpoint /etc/hosts; then
  echo "Removing old EKS private endpoints from /etc/hosts"
  sudo sed -i "/$endpoint/d" /etc/hosts
fi

#
# Update /etc/hosts with EKS private endpoint entries
#
for item in $ips
do
    echo "Adding EKS Private Endpoint IP Addresses"
    echo "$item $endpoint" | sudo tee -a /etc/hosts
done
