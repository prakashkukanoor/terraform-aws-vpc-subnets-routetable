output "vpc" {
  value = aws_vpc.this.id
}

output "dmz_subnets" {
  value = [for key, value in aws_subnet.dmz: value.id ]
}

output "webserver_subnets" {
  value = [for key, value in aws_subnet.webserver: value.id ]
}
output "database_subnets" {
  value = [for key, value in aws_subnet.database: value.id ]
}