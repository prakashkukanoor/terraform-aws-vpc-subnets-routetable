output "public_subnet_ids" {
  value = aws_subnet.public[*]
}

output "private_subnet_ids" {
  value = aws_subnet.private[*]
}