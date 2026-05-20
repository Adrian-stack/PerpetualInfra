output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "public_subnet_id" {
  description = "Public subnet ID"
  value       = aws_subnet.public.id
}

output "app_security_group_id" {
  description = "Security group ID for the app instance"
  value       = aws_security_group.app.id
}

output "availability_zone" {
  description = "AZ used for the public subnet"
  value       = aws_subnet.public.availability_zone
}
