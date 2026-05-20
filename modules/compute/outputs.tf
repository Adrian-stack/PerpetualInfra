output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.app.id
}

output "public_ip" {
  description = "Elastic IP address"
  value       = aws_eip.app.public_ip
}

output "public_dns" {
  description = "Public DNS of the EC2 instance (used as CloudFront origin)"
  value       = aws_instance.app.public_dns
}

output "instance_role_arn" {
  description = "IAM role ARN attached to the instance"
  value       = aws_iam_role.ec2_app.arn
}

output "ebs_volume_id" {
  description = "EBS data volume ID"
  value       = aws_ebs_volume.data.id
}
