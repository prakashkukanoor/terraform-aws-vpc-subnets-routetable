locals {
  comman_tags = {
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
    local.comman_tags,
  { Name = "VPC-${var.environment}" })
}

resource "aws_subnet" "application_public" {
  count = length(var.application_public_subnets)

  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.application_public_subnets[count.index].ipv4_cidr
  map_public_ip_on_launch = true
  availability_zone       = var.application_public_subnets[count.index].az

  ipv6_cidr_block = var.enable_ipv6 ? cidrsubnet(aws_vpc.this.ipv6_cidr_block, 64, count.index) : null
  assign_ipv6_address_on_creation = var.enable_ipv6

  tags = merge(
    local.comman_tags,
  { Name = "Application-Public-${var.application_public_subnets[count.index].az}" })
}

# resource "aws_subnet" "application_private" {
#   count = length(var.application_private_subnets)

#   vpc_id     = aws_vpc.this.id
#   cidr_block = var.application_private_subnets[count.index]
#   map_public_ip_on_launch = true
#   availability_zone = element(var.availability_zones, count.index)

#   ipv6_cidr_block           = var.enable_ipv6 ? cidrsubnet(aws_vpc.this.ipv6_cidr_block, 8, count.index + length(var.application_private_subnets)) : null
#   assign_ipv6_address_on_creation = var.enable_ipv6

#   tags = merge(
#     local.comman_tags,
#   { Name = "Application-Private-${var.environment}" })
# }

# resource "aws_subnet" "database_private" {
#   count = length(var.database_private_subnets)

#   vpc_id     = aws_vpc.this.id
#   cidr_block = var.database_private_subnets[count.index]
#   map_public_ip_on_launch = true
#   availability_zone = element(var.availability_zones, count.index)

#   ipv6_cidr_block           = var.enable_ipv6 ? cidrsubnet(aws_vpc.this.ipv6_cidr_block, 8, count.index + length(var.database_private_subnets)) : null
#   assign_ipv6_address_on_creation = var.enable_ipv6

#   tags = merge(
#     local.comman_tags,
#   { Name = "Database-Private-${var.environment}" })
# }