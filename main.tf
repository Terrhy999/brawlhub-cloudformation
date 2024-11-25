terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "us-east-1"

}

# Create a VPC for Brawlhub
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

    tags = {
    Name = "brawlhub-terraform"
  }
}

# Create an Internet Gateway for instances in private subnets to be able to reach the internet
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "BrawlhubIGW"
  }
}

# Create a Public Route Table
resource "aws_route_table" "public_route" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "PublicRouteTable"
  }
}

# Create route table associations for our public route tables
resource "aws_route_table_association" "public_a" {
  route_table_id = aws_route_table.public_route.id
  subnet_id = aws_subnet.public_subnet_a.id
}
resource "aws_route_table_association" "public_b" {
  route_table_id = aws_route_table.public_route.id
  subnet_id = aws_subnet.public_subnet_b.id
}

# Create a route table for our private subnets
resource "aws_route_table" "private_route" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw.id
  }

  tags = {
    Name = "PrivateRouteTable"
  }
}

# Create route table associations, so our private subnets use the private route table
resource "aws_route_table_association" "private_a" {
  route_table_id = aws_route_table.private_route.id
  subnet_id = aws_subnet.private_subnet_a.id
}
resource "aws_route_table_association" "private_b" {
  route_table_id = aws_route_table.private_route.id
  subnet_id = aws_subnet.private_subnet_b.id
}

# Allocate an elastic IP for our NAT Gateway
resource "aws_eip" "nat_eip" {
  instance = aws_instance.web.id
  domain   = "vpc"

  tags = {
    Name = "NatEIP"
  }
}

# Create a NAT Gateway for internet access in our private subnet
resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id = aws_subnet.public_subnet_a.id

  tags = {
    Name = "NatGateway"
  }
}

# We will need 3 subnets, 2 private subnets, and 2 public ones.
# This is because the database and application load balancer is required to be across multiple availablity zones.
# So 2 private subnets in 2 availability zones for our db, 2 public subnets in 2 AZs for our ALB.

# Create 2 Public Subnets in different AZs
resource "aws_subnet" "public_subnet_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.0.0/24"
  availability_zone       = "us-east-1a"  # First AZ
  map_public_ip_on_launch = true

  tags = {
    Name = "PublicSubnetA"
  }
}

resource "aws_subnet" "public_subnet_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1b"  # Second AZ
  map_public_ip_on_launch = true

  tags = {
    Name = "PublicSubnetB"
  }
}

# Create 2 Private Subnets in different AZs
resource "aws_subnet" "private_subnet_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1a"  # First AZ
  map_public_ip_on_launch = false

  tags = {
    Name = "PrivateSubnetA"
  }
}

resource "aws_subnet" "private_subnet_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "us-east-1b"  # Second AZ
  map_public_ip_on_launch = false

  tags = {
    Name = "PrivateSubnetB"
  }
}
