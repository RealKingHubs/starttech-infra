output "vpc_id" {
  value = aws_vpc.this.id
}

output "public_subnets" {
  value = aws_subnet.public[*].id
}

output "private_subnets" {
  value = aws_subnet.private[*].id
}

output "alb_security_group" {
  value = aws_security_group.alb.id
}

output "backend_security_group" {
  value = aws_security_group.backend.id
}

output "redis_security_group" {
  value = aws_security_group.redis.id
}