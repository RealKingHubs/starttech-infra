output "frontend_bucket_name" {
  value = aws_s3_bucket.frontend.bucket
}

# output "cloudfront_domain_name" {
#   value = aws_cloudfront_distribution.frontend.domain_name
# }

output "redis_endpoint" {
  value = aws_elasticache_cluster.redis.cache_nodes[0].address
}