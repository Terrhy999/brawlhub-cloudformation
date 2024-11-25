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
