output "vpc_id" {
  value = aws_vpc.this.id
}

output "application_public_subnet_ids" {
  value = aws_subnet.application_public[*].id
}

output "application_private_subnet_ids" {
  value = aws_subnet.application_private[*].id
}

output "database_private_subnet_ids" {
  value = aws_subnet.database_private[*].id
}

output "aws_vpce_gateway_dynamodb_id" {
  value = aws_vpc_endpoint.gateway["dynamodb"].id
}

output "aws_vpce_gateway_s3_id" {
  value = aws_vpc_endpoint.gateway["s3"].id
}

output "aws_vpce_interface_events_id" {
  value = aws_vpc_endpoint.interface["events"].id
}