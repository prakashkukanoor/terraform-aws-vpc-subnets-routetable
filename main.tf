locals {
  comman_tags = {
    Environment = var.environment
    ManagedBy   = var.team
    createdBy   = "terraform"
  }
}
provider "aws" {
  region = var.region
}

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