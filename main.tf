
locals {
  public_subnet_ids  = [for subnet in aws_subnet.public : subnet.id]
  private_subnet_ids = [for subnet in aws_subnet.private : subnet.id]
  public_subnet_azs  = toset([for subnet in aws_subnet.public : subnet.availability_zone])
}

resource "aws_vpc" "this" {
  cidr_block           = var.vpc.cidr_ipv4
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "Vpc-${var.environment}"
    Team = var.team
  }
}

resource "aws_subnet" "public" {
  vpc_id = aws_vpc.this.id

  for_each          = length(var.public_subnets) > 0 ? var.public_subnets : var.public_subnets
  cidr_block        = each.value.cidr_ipv4
  availability_zone = each.value.availability_zone

  tags = {
    Name = "Public-Subnet-${var.environment}-${each.value.availability_zone}"
    Team = var.team
  }
}

resource "aws_subnet" "private" {
  vpc_id = aws_vpc.this.id

  for_each          = length(var.private_subnets) > 0 ? var.private_subnets : var.private_subnets
  cidr_block        = each.value.cidr_ipv4
  availability_zone = each.value.availability_zone

  tags = {
    Name = "Private-Subnet-${var.environment}-${each.value.availability_zone}"
    Team = var.team
  }
}

resource "aws_internet_gateway" "this" {
  count  = length(local.public_subnet_ids) > 0 ? 1 : 0
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "IGW-${var.environment}"
    Team = var.team
  }
}

resource "aws_route_table" "public" {
    count = length(local.public_subnet_ids) >0 ? 1 : 0
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this[0].id
  }

  tags = {
    Name = "Public-route-${var.environment}"
    Team = var.team
  }

  depends_on = [aws_internet_gateway.this]
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id
  count  = length(local.public_subnet_azs) >0 ? length(local.public_subnet_azs): 0

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.this[count.index].id
  }

  tags = {
    Name = "Private-route-${var.environment}"
    Team = var.team
  }

  depends_on = [aws_nat_gateway.this]
}

resource "aws_nat_gateway" "this" {
  count         = length(aws_eip.natgw) >0 ? length(aws_eip.natgw) :0
  allocation_id = aws_eip.natgw[count.index].id
  subnet_id     = element(local.public_subnet_ids, count.index)

  tags = {
    Name = "NAT-GW-${var.environment}"
  }

  depends_on = [aws_internet_gateway.this]
}

resource "aws_eip" "natgw" {
  count = length(local.public_subnet_azs) >0 ? length(local.public_subnet_azs):0

  tags = {
    Name = "Nat-GW-${var.environment}"
    Team = var.team
  }
}

resource "aws_route_table_association" "public" {
  count          = length(local.public_subnet_ids) >0 ? length(local.public_subnet_ids): 0
  subnet_id      = element(local.public_subnet_ids, count.index)
  route_table_id = aws_route_table.public[0].id
}

resource "aws_route_table_association" "private" {
  count          = length(local.private_subnet_ids) >0 ? length(local.private_subnet_ids) :0
  subnet_id      = element(local.private_subnet_ids, count.index)
  route_table_id = aws_route_table.private[count.index].id
}