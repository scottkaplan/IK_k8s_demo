provider "aws" {
  region = "us-west-1"
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

resource "aws_vpc" "IK" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "IK"
  }
}

resource "aws_internet_gateway" "IK-igw" {
  vpc_id = aws_vpc.IK.id

  tags = {
    Name = "IK-igw"
  }
}

resource "aws_subnet" "public-us-west-1a" {
  vpc_id                  = aws_vpc.IK.id
  cidr_block              = "10.0.0.0/19"
  availability_zone       = "us-west-1a"
  map_public_ip_on_launch = true

  tags = {
    "Name"                       = "public-us-west-1a"
    "kubernetes.io/role/elb"     = "1"
    "kubernetes.io/cluster/demo" = "owned"
  }
}

resource "aws_subnet" "public-us-west-1c" {
  vpc_id                  = aws_vpc.IK.id
  cidr_block              = "10.0.96.0/19"
  availability_zone       = "us-west-1c"
  map_public_ip_on_launch = true

  tags = {
    "Name"                       = "public-us-west-1c"
    "kubernetes.io/role/elb"     = "1"
    "kubernetes.io/cluster/demo" = "owned"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.IK.id

  route = [
    {
      cidr_block                 = "0.0.0.0/0"
      gateway_id                 = aws_internet_gateway.IK-igw.id
      nat_gateway_id             = ""
      carrier_gateway_id         = ""
      destination_prefix_list_id = ""
      egress_only_gateway_id     = ""
      instance_id                = ""
      ipv6_cidr_block            = ""
      local_gateway_id           = ""
      network_interface_id       = ""
      transit_gateway_id         = ""
      vpc_endpoint_id            = ""
      vpc_peering_connection_id  = ""
    },
  ]

  tags = {
    Name = "public"
  }
}

resource "aws_route_table_association" "public-us-west-1a" {
  subnet_id      = aws_subnet.public-us-west-1a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public-us-west-1c" {
  subnet_id      = aws_subnet.public-us-west-1c.id
  route_table_id = aws_route_table.public.id
}
