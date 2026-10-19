
output "security_group_id" {
  description = "ID of the TravelMemory security group"
  value       = aws_security_group.travelmemory_sg.id
}

output "security_group_name" {
  description = "Name of the TravelMemory security group"
  value       = aws_security_group.travelmemory_sg.name
}

output "ec2_instance_id" {
  description = "TravelMemory EC2 instance ID"
  value       = aws_instance.travelmemory.id
}

output "ec2_public_ip" {
  description = "Public IP address of the TravelMemory server"
  value       = aws_instance.travelmemory.public_ip
}
output "ansible_control_instance_id" {
  description = "Ansible control node instance ID"
  value       = aws_instance.ansible_control.id
}

output "ansible_control_public_ip" {
  description = "Public IP address of Ansible control node"
  value       = aws_instance.ansible_control.public_ip
}