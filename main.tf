
resource "aws_vpc" "this" {
  cidr_block = var.vpc.cidr_ipv4
  enable_dns_support = true
  enable_dns_hostnames = true

  tags = {
    Name = "Vpc-${var.environment}"
    Team = var.team
  }
}

resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.this.id

  for_each = length(var.public_subnets) > 0 ? {for name, value in var.public_subnets: name => value} : var.public_subnets
  cidr_block = each.value.cidr_ipv4
  availability_zone = each.value.availability_zone

  tags = {
    Name = "Public-Subnet-${var.environment}-${each.value.availability_zone}"
    Team = var.team
  }
}

resource "aws_subnet" "private" {
  vpc_id     = aws_vpc.this.id

  for_each = length(var.private_subnets) > 0 ? {for name, value in var.private_subnets: name => value} : var.private_subnets
  cidr_block = each.value.cidr_ipv4
  availability_zone = each.value.availability_zone

  tags = {
    Name = "Private-Subnet-${var.environment}-${each.value.availability_zone}"
    Team = var.team
  }
}