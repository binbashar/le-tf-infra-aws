# Import blocks for existing VPC resources in devstg environment
# These imports are based on the tfplan.txt output showing resources to be created
# 
# IMPORTANT: Replace the placeholder IDs below with actual AWS resource IDs
# You can find these IDs using AWS CLI or Console:
#   - VPC ID: aws ec2 describe-vpcs --filters "Name=tag:Name,Values=bb-apps-devstg-vpc" --query "Vpcs[0].VpcId" --output text
#   - Subnet IDs: aws ec2 describe-subnets --filters "Name=tag:Name,Values=private-1a" --query "Subnets[0].SubnetId" --output text
#   - IGW ID: aws ec2 describe-internet-gateways --filters "Name=tag:Name,Values=bb-apps-devstg-vpc" --query "InternetGateways[0].InternetGatewayId" --output text
#   - NAT Gateway ID: aws ec2 describe-nat-gateways --filter "Name=tag:Name,Values=bb-apps-devstg-vpc-us-east-1a" --query "NatGateways[0].NatGatewayId" --output text
#   - EIP Allocation ID: aws ec2 describe-addresses --filters "Name=tag:Name,Values=bb-apps-devstg-vpc-us-east-1a" --query "Addresses[0].AllocationId" --output text
#   - Route Table IDs: aws ec2 describe-route-tables --filters "Name=tag:Name,Values=bb-apps-devstg-vpc-public" --query "RouteTables[0].RouteTableId" --output text

# ===========================================
# VPC - DEVSTG ACCOUNT - US-EAST-1 REGION
# ===========================================

# VPC (CIDR: 172.18.32.0/20, Name: bb-apps-devstg-vpc)
# Find VPC ID: aws ec2 describe-vpcs --filters "Name=tag:Name,Values=bb-apps-devstg-vpc" --query "Vpcs[0].VpcId" --output text
import {
  to = module.vpc.aws_vpc.this[0]
  id = "vpc-072f329fed6757e95" # Replace with actual VPC ID
}

# ===========================================
# SUBNETS
# ===========================================

# Private Subnet 1a (CIDR: 172.18.32.0/23, AZ: us-east-1a, Name: private-1a)
# Find Subnet ID: aws ec2 describe-subnets --filters "Name=tag:Name,Values=private-1a" "Name=vpc-id,Values=<vpc-id>" --query "Subnets[0].SubnetId" --output text
import {
  to = module.vpc.aws_subnet.private[0]
  id = "subnet-05d75d908f61d35e5" # Replace with actual subnet ID for private-1a
}

# Private Subnet 1b (CIDR: 172.18.34.0/23, AZ: us-east-1b, Name: private-1b)
# Find Subnet ID: aws ec2 describe-subnets --filters "Name=tag:Name,Values=private-1b" "Name=vpc-id,Values=<vpc-id>" --query "Subnets[0].SubnetId" --output text
import {
  to = module.vpc.aws_subnet.private[1]
  id = "subnet-094c287defbc07180" # Replace with actual subnet ID for private-1b
}

# Private Subnet 1c (CIDR: 172.18.36.0/23, AZ: us-east-1c, Name: private-1c)
# Find Subnet ID: aws ec2 describe-subnets --filters "Name=tag:Name,Values=private-1c" "Name=vpc-id,Values=<vpc-id>" --query "Subnets[0].SubnetId" --output text
import {
  to = module.vpc.aws_subnet.private[2]
  id = "subnet-0cec521de70ee76a3" # Replace with actual subnet ID for private-1c
}

# Public Subnet 1a (CIDR: 172.18.40.0/23, AZ: us-east-1a, Name: public-1a)
# Find Subnet ID: aws ec2 describe-subnets --filters "Name=tag:Name,Values=public-1a" "Name=vpc-id,Values=<vpc-id>" --query "Subnets[0].SubnetId" --output text
import {
  to = module.vpc.aws_subnet.public[0]
  id = "subnet-0d218f8cfd48fcddd" # Replace with actual subnet ID for public-1a
}

# Public Subnet 1b (CIDR: 172.18.42.0/23, AZ: us-east-1b, Name: public-1b)
# Find Subnet ID: aws ec2 describe-subnets --filters "Name=tag:Name,Values=public-1b" "Name=vpc-id,Values=<vpc-id>" --query "Subnets[0].SubnetId" --output text
import {
  to = module.vpc.aws_subnet.public[1]
  id = "subnet-021c484ecfbba66a9" # Replace with actual subnet ID for public-1b
}

# Public Subnet 1c (CIDR: 172.18.44.0/23, AZ: us-east-1c, Name: public-1c)
# Find Subnet ID: aws ec2 describe-subnets --filters "Name=tag:Name,Values=public-1c" "Name=vpc-id,Values=<vpc-id>" --query "Subnets[0].SubnetId" --output text
import {
  to = module.vpc.aws_subnet.public[2]
  id = "subnet-012079901076c3d0b" # Replace with actual subnet ID for public-1c
}

# ===========================================
# INTERNET GATEWAY
# ===========================================

# Internet Gateway (Name: bb-apps-devstg-vpc)
# Find IGW ID: aws ec2 describe-internet-gateways --filters "Name=tag:Name,Values=bb-apps-devstg-vpc" "Name=attachment.vpc-id,Values=<vpc-id>" --query "InternetGateways[0].InternetGatewayId" --output text
import {
  to = module.vpc.aws_internet_gateway.this[0]
  id = "igw-0037275ed5f8d18f4" # Replace with actual Internet Gateway ID
}

# ===========================================
# ELASTIC IP (for NAT Gateway)
# ===========================================

# Elastic IP for NAT Gateway (Name: bb-apps-devstg-vpc-us-east-1a)
# Find EIP Allocation ID: aws ec2 describe-addresses --filters "Name=tag:Name,Values=bb-apps-devstg-vpc-us-east-1a" --query "Addresses[0].AllocationId" --output text
#import {
#  to = module.vpc.aws_eip.nat[0]
#  id = "eipalloc-XXXXXXXXXXXXX" # Replace with actual Elastic IP Allocation ID
#}

# ===========================================
# NAT GATEWAY
# ===========================================

# NAT Gateway (Name: bb-apps-devstg-vpc-us-east-1a)
# Find NAT Gateway ID: aws ec2 describe-nat-gateways --filter "Name=tag:Name,Values=bb-apps-devstg-vpc-us-east-1a" --query "NatGateways[0].NatGatewayId" --output text
#import {
#  to = module.vpc.aws_nat_gateway.this[0]
#  id = "nat-XXXXXXXXXXXXX" # Replace with actual NAT Gateway ID
#}

# ===========================================
# ROUTE TABLES
# ===========================================

# Public Route Table (Name: bb-apps-devstg-vpc-public)
# Find Route Table ID: aws ec2 describe-route-tables --filters "Name=tag:Name,Values=bb-apps-devstg-vpc-public" "Name=vpc-id,Values=<vpc-id>" --query "RouteTables[0].RouteTableId" --output text
import {
  to = module.vpc.aws_route_table.public[0]
  id = "rtb-0923da71d5640916a" # Replace with actual public route table ID
}

# Private Route Table (Name: bb-apps-devstg-vpc-private)
# Find Route Table ID: aws ec2 describe-route-tables --filters "Name=tag:Name,Values=bb-apps-devstg-vpc-private" "Name=vpc-id,Values=<vpc-id>" --query "RouteTables[0].RouteTableId" --output text
import {
  to = module.vpc.aws_route_table.private[0]
  id = "rtb-0bb0ddcc1aaece2c4" # Replace with actual private route table ID
}

# ===========================================
# ROUTE TABLE ASSOCIATIONS
# ===========================================

# Route Table Association: Public Subnet 1a -> Public Route Table
# Find Association ID: aws ec2 describe-route-tables --route-table-ids <public-rt-id> --query "RouteTables[0].Associations[?SubnetId=='<public-subnet-1a-id>'].RouteTableAssociationId" --output text
import {
  to = module.vpc.aws_route_table_association.public[0]
  id = "subnet-0d218f8cfd48fcddd/rtb-0923da71d5640916a" # Replace with actual route table association ID (public-1a)
}

# Route Table Association: Public Subnet 1b -> Public Route Table
# Find Association ID: aws ec2 describe-route-tables --route-table-ids <public-rt-id> --query "RouteTables[0].Associations[?SubnetId=='<public-subnet-1b-id>'].RouteTableAssociationId" --output text
import {
  to = module.vpc.aws_route_table_association.public[1]
  id = "subnet-021c484ecfbba66a9/rtb-0923da71d5640916a" # Replace with actual route table association ID (public-1b)
}

# Route Table Association: Public Subnet 1c -> Public Route Table
# Find Association ID: aws ec2 describe-route-tables --route-table-ids <public-rt-id> --query "RouteTables[0].Associations[?SubnetId=='<public-subnet-1c-id>'].RouteTableAssociationId" --output text
import {
  to = module.vpc.aws_route_table_association.public[2]
  id = "subnet-012079901076c3d0b/rtb-0923da71d5640916a" # Replace with actual route table association ID (public-1c)
}

# Route Table Association: Private Subnet 1a -> Private Route Table
# Find Association ID: aws ec2 describe-route-tables --route-table-ids <private-rt-id> --query "RouteTables[0].Associations[?SubnetId=='<private-subnet-1a-id>'].RouteTableAssociationId" --output text
import {
  to = module.vpc.aws_route_table_association.private[0]
  id = "subnet-05d75d908f61d35e5/rtb-0bb0ddcc1aaece2c4" # Replace with actual route table association ID (private-1a)
}

# Route Table Association: Private Subnet 1b -> Private Route Table
# Find Association ID: aws ec2 describe-route-tables --route-table-ids <private-rt-id> --query "RouteTables[0].Associations[?SubnetId=='<private-subnet-1b-id>'].RouteTableAssociationId" --output text
import {
  to = module.vpc.aws_route_table_association.private[1]
  id = "subnet-094c287defbc07180/rtb-0bb0ddcc1aaece2c4" # Replace with actual route table association ID (private-1b)
}

# Route Table Association: Private Subnet 1c -> Private Route Table
# Find Association ID: aws ec2 describe-route-tables --route-table-ids <private-rt-id> --query "RouteTables[0].Associations[?SubnetId=='<private-subnet-1c-id>'].RouteTableAssociationId" --output text
import {
  to = module.vpc.aws_route_table_association.private[2]
  id = "subnet-0cec521de70ee76a3/rtb-0bb0ddcc1aaece2c4" # Replace with actual route table association ID (private-1c)
}

# ===========================================
# ROUTES
# ===========================================

# Route: Public Route Table -> Internet Gateway (0.0.0.0/0)
# Note: Routes use format: <route-table-id>_<destination-cidr-block>
# Find Route Table ID first, then use format: <rt-id>_0.0.0.0/0
import {
  to = module.vpc.aws_route.public_internet_gateway[0]
  id = "rtb-0923da71d5640916a_0.0.0.0/0" # Replace: <public-route-table-id>_0.0.0.0/0
}
#
# Route: Private Route Table -> NAT Gateway (0.0.0.0/0)
# Note: Routes use format: <route-table-id>_<destination-cidr-block>
# Find Route Table ID first, then use format: <rt-id>_0.0.0.0/0
#import {
#  to = module.vpc.aws_route.private_nat_gateway[0]
#  id = "rtb-0bb0ddcc1aaece2c4_0.0.0.0/0" # Replace: <private-route-table-id>_0.0.0.0/0
#}

# ===========================================
# DEFAULT RESOURCES
# ===========================================

# Default Network ACL (Name: bb-apps-devstg-vpc-default)
# Find Default Network ACL ID: aws ec2 describe-network-acls --filters "Name=default,Values=true" "Name=vpc-id,Values=vpc-072f329fed6757e95" --query "NetworkAcls[0].NetworkAclId" --output text
#import {
#  to = module.vpc.aws_default_network_acl.this[0]
#  id = "acl-0b19ecf9ac818d26c" # Default Network ACL ID from plan
#}

# Default Route Table (Name: bb-apps-devstg-vpc-default)
# Find Default Route Table ID: aws ec2 describe-route-tables --filters "Name=association.main,Values=true" "Name=vpc-id,Values=vpc-072f329fed6757e95" --query "RouteTables[0].RouteTableId" --output text
# NOTE: This import is commented out because aws_default_route_table.default is only created when manage_default_route_table=true
# and the VPC is being created (not imported). If you need to manage the default route table, ensure manageDefaultRouteTable=true
# in your vpc_config.defaultResources, and the resource will be created/imported automatically.
#import {
#  to = module.vpc.aws_default_route_table.default[0]
#  id = "rtb-0a38bc921c550919c" # Default Route Table ID from plan
#}

# Default Security Group (Name: bb-apps-devstg-vpc-default)
# Find Default Security Group ID: aws ec2 describe-security-groups --filters "Name=group-name,Values=default" "Name=vpc-id,Values=vpc-072f329fed6757e95" --query "SecurityGroups[0].GroupId" --output text
import {
  to = module.vpc.aws_default_security_group.this[0]
  id = "sg-04f0a13d66f9fc2f4" # Replace with actual default security group ID (run AWS CLI command above to find it)
}

