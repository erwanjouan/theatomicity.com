resource "aws_cloudfront_distribution" "this" {
  provider            = aws.cloudfront
  count               = length(local.domains)
  enabled             = true
  default_root_object = "index.html"
  price_class         = "PriceClass_100"
  aliases             = [local.domains[count.index]]
  is_ipv6_enabled     = true
  # web_acl_id          = aws_waf_web_acl.this.id // disabled because it costs

  // Default block

  origin {

    domain_name = local.website_endpoints[count.index]
    origin_id   = local.domains[count.index]

    // main > S3 origin with OAI
    // redirect > S3 static website with custom origin

    dynamic "custom_origin_config" {
      for_each = [local.domains[count.index]]
      content {
        http_port              = 80
        https_port             = 443
        origin_protocol_policy = "http-only"
        origin_ssl_protocols   = ["TLSv1", "TLSv1.1", "TLSv1.2"]
      }
    }
  }


  default_cache_behavior {
    allowed_methods = [
      "GET",
    "HEAD"]
    cached_methods = [
      "GET",
    "HEAD"]
    target_origin_id = local.domains[count.index]
    compress         = var.enable_gzip

    forwarded_values {
      query_string = false

      headers = [
        "Content-Type",
        "Accept",
        "Authorization"
      ]

      cookies {
        forward           = "whitelist"
        whitelisted_names = ["id_token"]
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000

  }

  // End Default block

  // BUCKET specific block, only for www.* distribution

  dynamic "origin" {
    for_each = ! (local.domains[count.index] == var.domain) ? var.www_buckets : []
    iterator = www_s3_bucket
    content {
      domain_name = data.aws_s3_bucket.origin[www_s3_bucket.value].bucket_regional_domain_name
      origin_id   = "S3-${www_s3_bucket.value}"

      s3_origin_config {
        origin_access_identity = aws_cloudfront_origin_access_identity.this.cloudfront_access_identity_path
      }
    }
  }

  dynamic "ordered_cache_behavior" {
    for_each = ! (local.domains[count.index] == var.domain) ? var.www_buckets : []
    iterator = www_s3_bucket
    content {
      path_pattern     = "/private/${www_s3_bucket.value}/*"
      allowed_methods  = ["GET", "HEAD", "OPTIONS"]
      cached_methods   = ["GET", "HEAD", "OPTIONS"]
      target_origin_id = "S3-${www_s3_bucket.value}"

      forwarded_values {
        query_string = false
        headers = [
          "Content-Type",
          "Accept",
          "Authorization"
        ]
        cookies {
          forward           = "whitelist"
          whitelisted_names = ["id_token"]
        }
      }
      lambda_function_association {
        event_type   = "origin-request"
        lambda_arn   = aws_lambda_function.edge.qualified_arn
        include_body = false
      }

      min_ttl                = 0
      default_ttl            = 86400
      max_ttl                = 31536000
      compress               = true
      viewer_protocol_policy = "redirect-to-https"
    }
  }

  // End kubernetes

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = element(split(",", data.terraform_remote_state.cert.outputs.aws_acm_certificate_ssl), count.index)
    minimum_protocol_version = "TLSv1"
    ssl_support_method       = "sni-only"
  }

  # Cache behavior with precedence 0


  custom_error_response {
    error_code            = 403
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 300
  }

  custom_error_response {
    error_code            = 404
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 300
  }
}

resource "aws_cloudfront_origin_access_identity" "this" {
  comment = "the origin access identity of www domain"
}