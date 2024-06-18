locals {
  comman_tags = {
    Environment = var.environment
    ManagedBy   = var.team
  }
}
provider "aws" {
  region = var.region
}

resource "aws_vpc" "this" {
  cidr_block           = var.vpc.cidr_block_ipv4
  instance_tenancy     = "default"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(
    local.comman_tags,
  { Name = "VPC-${var.environment}" })
}

resource "aws_subnet" "dmz" {
  for_each   = { for idx, value in var.dmz_subnets : idx => value }
  cidr_block = each.value
  vpc_id     = aws_vpc.this.id

  availability_zone = element(var.availability_zones, each.key % length(var.availability_zones))
    
  tags = merge(
    local.comman_tags,
    { Name = "dmz-public-${element(var.availability_zones, each.key % length(var.availability_zones))}-${var.environment}" }
  )
}

resource "aws_subnet" "webserver" {
  for_each   = { for idx, value in var.webserver_subnets : idx => value }
  cidr_block = each.value
  vpc_id     = aws_vpc.this.id

  availability_zone = element(var.availability_zones, each.key % length(var.availability_zones))

  tags = merge(
    local.comman_tags,
    { Name = "webserver-private-${element(var.availability_zones, each.key % length(var.availability_zones))}-${var.environment}" }
  )
}

resource "aws_subnet" "database" {
  for_each   = { for idx, value in var.database_subnets : idx => value }
  cidr_block = each.value
  vpc_id     = aws_vpc.this.id

  availability_zone = element(var.availability_zones, each.key % length(var.availability_zones))

  tags = merge(
    local.comman_tags,
    { Name = "database-private-${element(var.availability_zones, each.key % length(var.availability_zones))}-${var.environment}" }
  )
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(
    local.comman_tags,
    { Name = "igw-${var.environment}" }
  )
}

resource "aws_eip" "nat_ips" {
  count = length(var.availability_zones)

  tags = merge(
    local.comman_tags,
    { Name = "eip-${var.environment}" }
  )
}

resource "aws_nat_gateway" "this" {
  for_each      = { for idx, value in aws_eip.nat_ips : idx => value }
  allocation_id = each.value.id
  subnet_id     = aws_subnet.dmz[each.key].id

  tags = merge(
    local.comman_tags,
    { Name = "nat-${var.environment}" }
  )

  depends_on = [aws_internet_gateway.this, aws_eip.nat_ips]
}

resource "aws_route_table" "dmz" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = merge(
    local.comman_tags,
    { Name = "dmz-public-route-${var.environment}" }
  )
}

resource "aws_route_table" "webserver" {
  count = length(aws_nat_gateway.this)

  vpc_id = aws_vpc.this.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this[count.index].id
  }

  tags = merge(
    local.comman_tags,
    { Name = "webserver-private-route-${var.environment}" }
  )

  depends_on = [aws_nat_gateway.this]
}

resource "aws_route_table" "database" {
  count = length(aws_nat_gateway.this)

  vpc_id = aws_vpc.this.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this[count.index].id
  }

  tags = merge(
    local.comman_tags,
    { Name = "database-private-route-${var.environment}" }
  )

  depends_on = [aws_nat_gateway.this]
}

resource "aws_route_table_association" "dmz" {
  count          = length(aws_subnet.dmz)
  subnet_id      = aws_subnet.dmz[count.index].id
  route_table_id = aws_route_table.dmz.id
}

resource "aws_route_table_association" "webserver" {
  count          = length(aws_route_table.webserver)
  subnet_id      = aws_subnet.webserver[count.index].id
  route_table_id = aws_route_table.webserver[count.index].id
}
resource "aws_route_table_association" "database" {
  count          = length(aws_route_table.database)
  subnet_id      = aws_subnet.database[count.index].id
  route_table_id = aws_route_table.database[count.index].id
}