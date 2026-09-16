output "vpc_id" {
  value = var.vpc_id
}

output "public_subnet_id" {
  value = aws_subnet.public.id
}

output "internet_gateway_id" {
  value = aws_internet_gateway.this.id
}

output "instance_id" {
  value = aws_instance.kind.id
}

output "public_ip" {
  value = aws_instance.kind.public_ip
}

output "private_ip" {
  value = aws_instance.kind.private_ip
}

output "ssh_command" {
  value = "ssh -i <your-key.pem> ec2-user@${aws_instance.kind.public_ip}"
}

output "grafana_url" {
  value = "http://${aws_instance.kind.public_ip}:3001"
}

output "prometheus_url" {
  value = "http://${aws_instance.kind.public_ip}:9090"
}

output "grafana_credentials" {
  value     = "admin / ${var.grafana_admin_password}"
  sensitive = true
}