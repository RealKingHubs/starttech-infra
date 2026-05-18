output "alb_security_group" {
  value = aws_security_group.alb.id
}

output "backend_security_group" {
  value = aws_security_group.backend.id
}

output "redis_security_group" {
  value = aws_security_group.redis.id
}