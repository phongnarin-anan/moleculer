provider "aws" {
  alias = "us-east-1"
}

resource "aws_cloudfront_distribution" "alb_distribution" {
  origin {
    domain_name = aws_lb.main.dns_name
    origin_id   = "ALBOrigin"
    custom_origin_config {
      origin_protocol_policy = "https-only"
      http_port              = "80"
      https_port             = "443"
      origin_ssl_protocols   = ["TLSv1.2"]
      origin_read_timeout    = 60
    }
  }

  enabled         = true
  is_ipv6_enabled = true
  aliases         = ["moleculer.panan.info"]
  #   web_acl_id      = aws_wafv2_web_acl.aws_rules.arn
  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "ALBOrigin"

    forwarded_values {
      query_string = true
      headers      = ["*"]
      cookies {
        forward = "all"
      }
    }

    viewer_protocol_policy = "https-only"
    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000
  }

  ordered_cache_behavior {
    path_pattern     = "*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "ALBOrigin"

    forwarded_values {
      query_string = true
      headers      = ["*"]
      cookies {
        forward = "all"
      }
    }

    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }

  price_class = "PriceClass_All"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    #cloudfront_default_certificate = true
    acm_certificate_arn      = var.virginia_cert_arn
    minimum_protocol_version = "TLSv1.2_2019"
    ssl_support_method       = "sni-only"
  }
}

# resource "aws_wafv2_web_acl" "aws_rules" {
#   provider    = aws.us-east-1
#   name        = "aws-rules"
#   description = "aws-rules managed rule."
#   scope       = "CLOUDFRONT"

#   default_action {
#     block {}
#   }

#   rule {
#     name     = "AWSManagedRulesCommonRuleSet"
#     priority = 20

#     override_action {
#       none {}
#     }

#     statement {
#       managed_rule_group_statement {
#         name        = "AWSManagedRulesCommonRuleSet"
#         vendor_name = "AWS"
#       }
#     }

#     visibility_config {
#       cloudwatch_metrics_enabled = true
#       metric_name                = "AWSManagedRulesCommonRuleSetMetric"
#       sampled_requests_enabled   = true
#     }
#   }


#   rule {
#     name     = "AWSManagedRulesKnownBadInputsRuleSet"
#     priority = 21

#     override_action {
#       none {}
#     }

#     statement {
#       managed_rule_group_statement {
#         name        = "AWSManagedRulesKnownBadInputsRuleSet"
#         vendor_name = "AWS"
#       }
#     }

#     visibility_config {
#       cloudwatch_metrics_enabled = true
#       metric_name                = "AWSManagedRulesKnownBadInputsRuleSetMetric"
#       sampled_requests_enabled   = true
#     }
#   }

#   rule {
#     name     = "AWSManagedRulesSQLiRuleSet"
#     priority = 22

#     override_action {
#       none {}
#     }

#     statement {
#       managed_rule_group_statement {
#         name        = "AWSManagedRulesSQLiRuleSet"
#         vendor_name = "AWS"
#       }
#     }

#     visibility_config {
#       cloudwatch_metrics_enabled = true
#       metric_name                = "AWSManagedRulesSQLiRuleSetMetric"
#       sampled_requests_enabled   = true
#     }
#   }

#   rule {
#     name     = "AWSManagedRulesLinuxRuleSet"
#     priority = 23

#     override_action {
#       none {}
#     }

#     statement {
#       managed_rule_group_statement {
#         name        = "AWSManagedRulesLinuxRuleSet"
#         vendor_name = "AWS"
#       }
#     }

#     visibility_config {
#       cloudwatch_metrics_enabled = true
#       metric_name                = "AWSManagedRulesLinuxRuleSetMetric"
#       sampled_requests_enabled   = true
#     }
#   }

#   rule {
#     name     = "AWSManagedRulesAmazonIpReputationList"
#     priority = 24

#     override_action {
#       none {}
#     }

#     statement {
#       managed_rule_group_statement {
#         name        = "AWSManagedRulesAmazonIpReputationList"
#         vendor_name = "AWS"
#       }
#     }

#     visibility_config {
#       cloudwatch_metrics_enabled = true
#       metric_name                = "AWSManagedRulesAmazonIpReputationListMetric"
#       sampled_requests_enabled   = true
#     }
#   }

#   rule {
#     name     = "AWSManagedRulesUnixRuleSet"
#     priority = 25

#     override_action {
#       none {}
#     }

#     statement {
#       managed_rule_group_statement {
#         name        = "AWSManagedRulesUnixRuleSet"
#         vendor_name = "AWS"
#       }
#     }

#     visibility_config {
#       cloudwatch_metrics_enabled = true
#       metric_name                = "AWSManagedRulesUnixRuleSetMetric"
#       sampled_requests_enabled   = true
#     }
#   }

#   visibility_config {
#     cloudwatch_metrics_enabled = true
#     metric_name                = "aws-rules-acl"
#     sampled_requests_enabled   = true
#   }
# }
