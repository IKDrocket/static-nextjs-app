terraform {
  required_version = "~> 1.7.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.42.0"
    }
  }
  backend "s3" {
    bucket = "static-nextjs-ikdrocket-app-terraform-state"
    # 以下情報はtfbackend/envs/{env}に記載する
    # key    = "KEY"
    # profile = "PROFILE"
    # region = "REGION"
  }
}

provider "aws" {
  # profile = "terraform"
  region = "ap-northeast-1"
}

# ------------------------------------------------
# Variables (値はterraform.tfvarsで管理, gitignore対象)
# ------------------------------------------------

variable "environment" {
  type        = string
  description = "ブランチ名・PR番号などの環境識別子"
}


# ------------------------------------------------
# S3
# ------------------------------------------------

resource "aws_s3_bucket" "static_nextjs_app" {
  bucket = "static-nextjs-app-ikdrocket-${var.environment}"
  tags = {
    Name = "static-nextjs-app-${var.environment}"
  }
}

# バケットポリシー
data "aws_iam_policy_document" "static_nextjs_app" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.static_nextjs_app.arn}/*"]
    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = ["${aws_cloudfront_distribution.static_nextjs_app.arn}"]
    }
  }
}

resource "aws_s3_bucket_policy" "static_nextjs_app" {
  bucket = aws_s3_bucket.static_nextjs_app.id
  policy = data.aws_iam_policy_document.static_nextjs_app.json
}

# ------------------------------------------------
# CloudFront
# ------------------------------------------------

resource "aws_cloudfront_origin_access_control" "static_nextjs_app" {
  name                              = "static-nextjs-app-${var.environment}"
  origin_access_control_origin_type = "s3"
  signing_protocol                  = "sigv4"
  signing_behavior                  = "always"
}

resource "aws_cloudfront_function" "static_nextjs_app" {
  name    = "static-nextjs-app-${var.environment}"
  comment = "nextjsの静的サイトでURLをリライトする関数"
  runtime = "cloudfront-js-2.0"
  publish = true

  code = file("functions/rewrite-url.js")
}


data "aws_cloudfront_cache_policy" "managed_caching_optimized" {
  name = "Managed-CachingOptimized"
}
# CloudFrontディストリビューション
resource "aws_cloudfront_distribution" "static_nextjs_app" {
  enabled         = true
  is_ipv6_enabled = true
  # default_root_object = "index.html"

  # オリジンの設定
  origin {
    domain_name              = aws_s3_bucket.static_nextjs_app.bucket_regional_domain_name
    origin_id                = aws_s3_bucket.static_nextjs_app.id
    origin_access_control_id = aws_cloudfront_origin_access_control.static_nextjs_app.id
  }

  # キャッシュの設定
  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = aws_s3_bucket.static_nextjs_app.id
    viewer_protocol_policy = "https-only"

    # キャッシュポリシー
    cache_policy_id = data.aws_cloudfront_cache_policy.managed_caching_optimized.id

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.static_nextjs_app.arn
    }

  }

  # 国ごとのコンテンツ制限設定
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  depends_on = [aws_cloudfront_function.static_nextjs_app, aws_cloudfront_origin_access_control.static_nextjs_app]

  tags = {
    Name = "static-nextjs-app-${var.environment}"
  }
}


output "s3_bucket_name" {
  value = aws_s3_bucket.static_nextjs_app.bucket
}

output "cloudfront_distribution_id" {
  value = aws_cloudfront_distribution.static_nextjs_app.id
}

output "cloudfront_distribution_domain_name" {
  value = aws_cloudfront_distribution.static_nextjs_app.domain_name
}


# # ------------------------------------------------
# # Next.jsのビルドイメージをs3にアップロード
# # ------------------------------------------------
# resource "null_resource" "update_source_files" {
#   provisioner "local-exec" {
#     command = "aws s3 sync --profile terraform ../out s3://${aws_s3_bucket.static_nextjs_app.bucket}/"
#   }
# }

# # ------------------------------------------------
# # CloudFrontのキャッシュを削除
# # ------------------------------------------------

# resource "null_resource" "invalidate_cache" {
#   provisioner "local-exec" {
#     command = "aws cloudfront create-invalidation --profile terraform --distribution-id ${aws_cloudfront_distribution.static_nextjs_app.id} --paths '/*'"
#   }
# }
