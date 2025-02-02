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
  cidr_block           = var.vpc_cidr_ipv4
  assign_generated_ipv6_cidr_block = true
  instance_tenancy     = "default"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(
    local.comman_tags,
  { Name = "VPC-${var.environment}" })
}

resource "aws_subnet" "application_public" {
  count = length(var.application_public_subnets)

  vpc_id     = aws_vpc.this.id
  cidr_block = var.application_public_subnets[count.index]
  map_public_ip_on_launch = true
  availability_zone = element(var.availability_zones, count.index)
  
  ipv6_cidr_block           = var.enable_ipv6 ? cidrsubnet(aws_vpc.this[0].ipv6_cidr_block, 8, count.index + length(var.application_public_subnets)) : null
  assign_ipv6_address_on_creation = var.enable_ipv6

  tags = merge(
    local.comman_tags,
  { Name = "Application-Public-${var.environment}" })
}