output "instance_public_ip" {
  description = "Public IP of the Ubuntu instance"
  value       = aws_instance.ubuntu.public_ip
}

output "ssh_command" {
  description = "SSH command to connect"
  value       = "ssh ubuntu@${aws_instance.ubuntu.public_ip}"
}
