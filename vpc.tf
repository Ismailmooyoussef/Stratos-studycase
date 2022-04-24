# Create a VPC
resource "aws_vpc" "main" {
    cidr_block = "10.0.0.0/16"
    instance_tenancy = "default"
    enable_dns_support = true
    enable_dns_hostnames = true

    tags = {
    Name = "main"
  }
}

data "aws_availability_zones" "available" {}

# Create subnets

# 2 small Subnets dedicated for EKS network interfaces
# Nodes & Load balancers will be launched in seperate subnets.
resource "aws_subnet" "eks_interfaces" {
  count                   = length(var.eks_interfaces_subnets)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = element(var.eks_interfaces_subnets,count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = false
  tags = {
  Name = "EKS_interfaces_private_Subnet"
  }
}

# Subnets where the Nodes will be launched
resource "aws_subnet" "private" {
  count                   = length(var.private_subnets)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = element(var.private_subnets,count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = false
  tags = {
  Name = "private_Subnet"
  "kubernetes.io/role/internal-elb" = 1    
  }
}

# Subnets where the External Load balancers will be launched
resource "aws_subnet" "public" {
  count                   = length(var.public_subnets)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = element(var.public_subnets,count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
  tags = {
  Name = "public_Subnet"
  "kubernetes.io/role/elb" = 1
  }
}


# Create the Internet Gateway
resource "aws_internet_gateway" "IGW" {
 vpc_id = aws_vpc.main.id
 tags = {
        Name = "My VPC Internet Gateway"
  }
}

# Create a Route table
resource "aws_route_table" "IGW_Route_table" {
 vpc_id = aws_vpc.main.id
  tags = {
        Name = "Route Table for IGW"
  }
}

# Add route to the Internet GW
resource "aws_route" "IGW_Route_table" {
  route_table_id         = aws_route_table.IGW_Route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.IGW.id
}


# Associate the Route Table with the Subnet
resource "aws_route_table_association" "public_subnet_associate" {
  count      = length(var.public_subnets)
  subnet_id  = element(aws_subnet.public.*.id, count.index)
  route_table_id = aws_route_table.IGW_Route_table.id
}


# Create the Internet-facing Security Group
resource "aws_security_group" "Public_Security_Group" {
  vpc_id       = aws_vpc.main.id
  name         = "Public_Security_Group"
#   description  = "Public_Security_Group"

  # allow ingress of port 22
  ingress {
    cidr_blocks = var.ssh_ingress_cidrBlock
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
  }

    ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
  }

    ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
  }

  # Open ALL traffic for testing
    ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    to_port     = 0
    protocol    = -1
  }


  # allow egress of all ports
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "Public Security Group"
  }
}

# Create the Internal Security Group
resource "aws_security_group" "Private_Security_Group" {
  vpc_id       = aws_vpc.main.id
  name         = "Private_Security_Group"

# allow ingress from the Public Security group
  ingress {
    security_groups = [aws_security_group.Public_Security_Group.id]
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    }

  ingress {
    security_groups = [aws_security_group.Public_Security_Group.id]
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    }

  # allow egress of all ports
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "Private Security Group"
  }

  # Open ALL traffic for testing
  ingress {
  security_groups = [aws_security_group.Public_Security_Group.id]
  from_port   = 0
  to_port     = 0
  protocol    = -1
  }
}

# Create a NAT Gateway

resource "aws_eip" "NAT_Gateway_EIP" {
  vpc      = true
}

resource "aws_nat_gateway" "NAT_Gateway" {
  count      = "${length(var.public_subnet)}"
  allocation_id = aws_eip.NAT_Gateway_EIP.id
  subnet_id     = "${element(aws_subnet.public.*.id, count.index)}" # To loop on the 3 subnets
  
}

# Create a Route table for NAT GW
resource "aws_route_table" "NAT_GW_Route_table" {
 vpc_id = aws_vpc.main.id
 tags = {
        Name = "Route Table for NAT GW"
  }
}

# Add route to the NAT GW
resource "aws_route" "Route_to_NAT_GW" {
  route_table_id         = aws_route_table.NAT_GW_Route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_nat_gateway.NAT_Gateway.id
}

resource "aws_route_table_association" "private_subnet_associate" {
  count      = length(var.private_subnets)
  subnet_id  = element(aws_subnet.private.*.id, count.index)
  route_table_id = aws_route_table.NAT_GW_Route_table.id
}

