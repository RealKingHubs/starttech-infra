output "alb_dns_name" {
  value = aws_lb.backend.dns_name
}

output "ecr_repository_url" {
  value = aws_ecr_repository.backend.repository_url
}

output "target_group_arn" {
  value = aws_lb_target_group.backend.arn
}