resource "aws_s3_bucket" "cloud_trail_logs_store_bucket" {
  bucket = var.bucket_name
  tags   = var.tags
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cloud_trail_bucket_encryption" {
  bucket = aws_s3_bucket.cloud_trail_logs_store_bucket.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.cloudtrail.arn
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_acl" "cloud_log_bucket_acl" {
  bucket = aws_s3_bucket.cloud_trail_logs_store_bucket.id
  acl    = "private"
}

resource "aws_s3_bucket_versioning" "cloud_log_bucket_versioning" {
  bucket = aws_s3_bucket.cloud_trail_logs_store_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "cloud_trail_logs_lifecycle" {
  bucket = aws_s3_bucket.cloud_trail_logs_store_bucket.id

  rule {
    id     = "archive-old-logs"
    status = "Enabled"

    filter {}

    transition {
      days          = 90
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 365
      storage_class = "GLACIER"
    }

    expiration {
      days = 730
    }
  }

  rule {
    id     = "abort-incomplete-uploads"
    status = "Enabled"

    filter {}

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

resource "aws_s3_bucket" "cloud_trail_access_logs" {
  bucket = "${var.bucket_name}-access-logs"
  tags   = var.tags
}

resource "aws_s3_bucket_server_side_encryption_configuration" "access_logs_encryption" {
  bucket = aws_s3_bucket.cloud_trail_access_logs.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "access_logs_block" {
  bucket = aws_s3_bucket.cloud_trail_access_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "access_logs_versioning" {
  bucket = aws_s3_bucket.cloud_trail_access_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "access_logs_lifecycle" {
  bucket = aws_s3_bucket.cloud_trail_access_logs.id

  rule {
    id     = "expire-access-logs"
    status = "Enabled"

    filter {}

    expiration {
      days = 90
    }
  }

  rule {
    id     = "abort-incomplete-uploads"
    status = "Enabled"

    filter {}

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

resource "aws_s3_bucket_logging" "cloud_trail_logs_logging" {
  bucket        = aws_s3_bucket.cloud_trail_logs_store_bucket.id
  target_bucket = aws_s3_bucket.cloud_trail_access_logs.id
  target_prefix = "access-logs/"
}

resource "aws_s3_bucket_public_access_block" "cloud_trail_logs_block" {
  bucket = aws_s3_bucket.cloud_trail_logs_store_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "cloud_trail_logs_store_bucket" {
  bucket = aws_s3_bucket.cloud_trail_logs_store_bucket.id

  depends_on = [aws_s3_bucket_public_access_block.cloud_trail_logs_block]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudTrailACLCheck"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = "arn:aws:s3:::${aws_s3_bucket.cloud_trail_logs_store_bucket.bucket}"
      },
      {
        Sid    = "AllowCloudTrailWrite"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "arn:aws:s3:::${aws_s3_bucket.cloud_trail_logs_store_bucket.bucket}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      },
      {
        Sid       = "DenyNonSSL"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          "arn:aws:s3:::${aws_s3_bucket.cloud_trail_logs_store_bucket.bucket}",
          "arn:aws:s3:::${aws_s3_bucket.cloud_trail_logs_store_bucket.bucket}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}
