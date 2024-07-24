output "AVAILABILITY_ZONE" {
  value = aws_subnet.easytrain-subnet-pub1.availability_zone
}

output "AMI_ID" {
  value = var.ami-id
}

output "KEY_NAME" {
  value = aws_launch_template.easytrain-lt.key_name
}
