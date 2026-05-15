# -----------------------------
# RANDOM SUFFIX
# -----------------------------

resource "random_id" "suffix" {
  byte_length = 4
}

# -----------------------------
# PRIVATE S3 BUCKET
# -----------------------------

resource "aws_s3_bucket" "frontend" {
  bucket = "${var.environment}-starttech-frontend-${random_id.suffix.hex}"

  force_destroy = true
}

# -----------------------------
# BLOCK ALL PUBLIC ACCESS
# -----------------------------

resource "aws_s3_bucket_public_access_block" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# -----------------------------
# ENABLE VERSIONING
# -----------------------------

resource "aws_s3_bucket_versioning" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  versioning_configuration {
    status = "Enabled"
  }
}

# -----------------------------
# SERVER SIDE ENCRYPTION
# -----------------------------

resource "aws_s3_bucket_server_side_encryption_configuration" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# -----------------------------
# ORIGIN ACCESS CONTROL
# -----------------------------

# resource "aws_cloudfront_origin_access_control" "frontend" {
#   name                              = "${var.environment}-frontend-oac"
#   description                       = "OAC for private frontend bucket"
#   origin_access_control_origin_type = "s3"

#   signing_behavior = "always"
#   signing_protocol = "sigv4"
# }

# -----------------------------
# CLOUDFRONT DISTRIBUTION
# -----------------------------

# resource "aws_cloudfront_distribution" "frontend" {
#   enabled             = true
#   default_root_object = "index.html"

#   origin {
#     domain_name = aws_s3_bucket.frontend.bucket_regional_domain_name
#     origin_id   = "frontendS3"

#     origin_access_control_id = aws_cloudfront_origin_access_control.frontend.id
#   }

#   default_cache_behavior {
#     target_origin_id       = "frontendS3"
#     viewer_protocol_policy = "redirect-to-https"

#     allowed_methods = [
#       "GET",
#       "HEAD",
#       "OPTIONS"
#     ]

#     cached_methods = [
#       "GET",
#       "HEAD"
#     ]

#     forwarded_values {
#       query_string = false

#       cookies {
#         forward = "none"
#       }
#     }
#   }

#   restrictions {
#     geo_restriction {
#       restriction_type = "none"
#     }
#   }

#   custom_error_response {
#     error_code            = 403
#     response_code         = 200
#     response_page_path    = "/index.html"
#     error_caching_min_ttl = 10
#   }

#   custom_error_response {
#     error_code            = 404
#     response_code         = 200
#     response_page_path    = "/index.html"
#     error_caching_min_ttl = 10
#   }

#   viewer_certificate {
#     cloudfront_default_certificate = true
#   }
# }

# -----------------------------
# S3 BUCKET POLICY FOR CLOUDFRONT
# -----------------------------

# resource "aws_s3_bucket_policy" "frontend" {
#   bucket = aws_s3_bucket.frontend.id

#   policy = jsonencode({
#     Version = "2012-10-17"

#     Statement = [
#       {
#         Sid    = "AllowCloudFrontServicePrincipalReadOnly"
#         Effect = "Allow"

#         Principal = {
#           Service = "cloudfront.amazonaws.com"
#         }

#         Action = [
#           "s3:GetObject"
#         ]

#         Resource = [
#           "${aws_s3_bucket.frontend.arn}/*"
#         ]

#         Condition = {
#           StringEquals = {
#             "AWS:SourceArn" = aws_cloudfront_distribution.frontend.arn
#           }
#         }
#       }
#     ]
#   })
# }

# -----------------------------
# ELASTICACHE SUBNET GROUP
# -----------------------------

resource "aws_elasticache_subnet_group" "redis" {
  name = "${var.environment}-redis-subnet-group"

  subnet_ids = var.private_subnets
}

# -----------------------------
# REDIS CLUSTER
# -----------------------------

resource "aws_elasticache_cluster" "redis" {
  cluster_id           = "${var.environment}-redis"
  engine               = "redis"
  node_type            = "cache.t3.micro"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis7"

  port = 6379

  subnet_group_name  = aws_elasticache_subnet_group.redis.name
  security_group_ids = [var.redis_security_group]
}