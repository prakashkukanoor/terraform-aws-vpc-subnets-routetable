locals {
  common_tags = {
    environment = var.environment
    managedBy   = var.team
    createdBy   = "terraform"
  }
}

# AWS region for infra creation
provider "aws" {
  region = var.region
}

# Create VPC with IPv4 and IPv6 CIDR
resource "aws_vpc" "this" {
  cidr_block                       = var.vpc_cidr_ipv4
  assign_generated_ipv6_cidr_block = true
  instance_tenancy                 = "default"
  enable_dns_hostnames             = true
  enable_dns_support               = true

  tags = merge(
    local.common_tags,
  { Name = "VPC-${var.environment}" })
}

resource "aws_subnet" "application_public" {
  count = length(var.application_public_subnets)

  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.application_public_subnets[count.index].ipv4_cidr
  map_public_ip_on_launch = true
  availability_zone       = element(var.availability_zone, count.index)

  ipv6_cidr_block                 = var.enable_ipv6 ? cidrsubnet(aws_vpc.this.ipv6_cidr_block, 8, var.application_public_subnets[count.index].ipv6_index) : null
  assign_ipv6_address_on_creation = var.enable_ipv6

  tags = merge(
    local.common_tags,
  { Name = "Application-Public-${element(var.availability_zone, count.index)}" })
}

resource "aws_subnet" "application_private" {
  count = length(var.application_private_subnets)

  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.application_private_subnets[count.index].ipv4_cidr
  map_public_ip_on_launch = true
  availability_zone       = element(var.availability_zone, count.index)

  ipv6_cidr_block                 = var.enable_ipv6 ? cidrsubnet(aws_vpc.this.ipv6_cidr_block, 8, var.application_private_subnets[count.index].ipv6_index) : null
  assign_ipv6_address_on_creation = var.enable_ipv6

  tags = merge(
    local.common_tags,
  { Name = "Application-Private-${element(var.availability_zone, count.index)}" })
}

resource "aws_subnet" "database_private" {
  count = length(var.database_private_subnets)

  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.database_private_subnets[count.index].ipv4_cidr
  map_public_ip_on_launch = true
  availability_zone       = element(var.availability_zone, count.index)

  ipv6_cidr_block                 = var.enable_ipv6 ? cidrsubnet(aws_vpc.this.ipv6_cidr_block, 8, var.database_private_subnets[count.index].ipv6_index) : null
  assign_ipv6_address_on_creation = var.enable_ipv6

  tags = merge(
    local.common_tags,
  { Name = "Database-Private-${element(var.availability_zone, count.index)}" })
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(
    local.common_tags,
  { Name = "IGW-${var.environment}" })
}

resource "aws_eip" "natgw" {
  count = length(var.availability_zone)

  tags = merge(
    local.common_tags,
  { Name = "EIP-NATGW-${var.environment}" })
}

resource "aws_nat_gateway" "this" {
  count         = length(var.availability_zone)
  allocation_id = aws_eip.natgw[count.index].id
  subnet_id     = aws_subnet.application_public[count.index].id

  tags = merge(
    local.common_tags,
  { Name = "NATGW-${var.availability_zone[count.index]}-${var.environment}" })

  depends_on = [aws_subnet.application_public, aws_internet_gateway.this]
}

resource "aws_egress_only_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(
    local.common_tags,
  { Name = "Egress-IGW-${var.environment}" })
}

resource "aws_route_table" "application_public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }
  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.this.id
  }

  depends_on = [aws_subnet.application_public, aws_internet_gateway.this]

  tags = merge(
    local.common_tags,
  { Name = "Application-Public-RouteTable-${var.environment}" })
}

resource "aws_route_table_association" "application_public" {
  count = length(aws_subnet.application_public)

  subnet_id      = aws_subnet.application_public[count.index].id
  route_table_id = aws_route_table.application_public.id
}

resource "aws_route_table" "application_private" {
  count  = length(var.availability_zone)
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.this[count.index].id
  }
  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_egress_only_internet_gateway.this.id
  }

  depends_on = [aws_subnet.application_private, aws_nat_gateway.this]

  tags = merge(
    local.common_tags,
  { Name = "Application-Private-RouteTable-${var.environment}" })
}

resource "aws_route_table_association" "application_private" {
  count = length(aws_subnet.application_private)

  subnet_id      = aws_subnet.application_private[count.index].id
  route_table_id = element(aws_route_table.application_private[*].id, count.index)
}

resource "aws_route_table" "database_private" {
  count  = length(var.availability_zone)
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.this[count.index].id
  }
  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_egress_only_internet_gateway.this.id
  }

  depends_on = [aws_subnet.database_private, aws_nat_gateway.this, aws_egress_only_internet_gateway.this]

  tags = merge(
    local.common_tags,
  { Name = "Database-Private-RouteTable-${var.environment}" })
}

resource "aws_route_table_association" "database_private" {
  count = length(aws_subnet.database_private)

  subnet_id      = aws_subnet.database_private[count.index].id
  route_table_id = element(aws_route_table.database_private[*].id, count.index)
}

# Create VPC Endpoint for S3
resource "aws_vpc_endpoint" "gateway" {
  for_each = {for key, value in var.vpc_gateway_endpoints: key => value if value}
  vpc_id             = aws_vpc.this.id
  service_name       = "com.amazonaws.us-east-1.${each.key}"
  vpc_endpoint_type  = "Gateway"
  route_table_ids    = aws_route_table.application_private[*].id

  tags = merge(
    local.common_tags,
  { Name = "VPCE-${each.key}-${var.environment}" })

}