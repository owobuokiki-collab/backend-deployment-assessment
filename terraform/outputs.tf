output "bastion_public_ip" {
  value = aws_eip.bastion_eip.public_ip
}

output "backend_private_ip" {
  value = aws_instance.backend_server.private_ip
}

output "mongodb_private_ip" {
  value = aws_instance.mongodb_server.private_ip
}

output "alb_dns_name" {
  value = aws_lb.startuptech_alb.dns_name
}
