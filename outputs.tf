output "AVAILABILITY_ZONE" {
  value = aws_subnet.easytrain-subnet-pub1.availability_zone
}

output "AMI_ID" {
  value = var.ami-id
}

output "ELASTIC_IP" {
  value = aws_eip.easytrain-eip.public_ip
}

output "KEY_NAME" {
  value = aws_instance.easytrain-ec2.key_name
}
