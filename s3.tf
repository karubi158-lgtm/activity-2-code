
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

locals {
  primary_bucket_name   = "${var.project_name}-mumbai-${random_id.bucket_suffix.hex}"
  secondary_bucket_name = "${var.project_name}-singapore-${random_id.bucket_suffix.hex}"
  audit_bucket_name     = "${var.project_name}-audit-${random_id.bucket_suffix.hex}"
}

resource "aws_s3_bucket" "primary" {
  bucket = local.primary_bucket_name
}

resource "aws_s3_bucket" "secondary" {
  provider = aws.singapore
  bucket   = local.secondary_bucket_name
}

resource "aws_s3_bucket_versioning" "primary" {
  bucket = aws_s3_bucket.primary.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_versioning" "secondary" {
  provider = aws.singapore
  bucket   = aws_s3_bucket.secondary.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "primary" {
  bucket = aws_s3_bucket.primary.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "secondary" {
  provider = aws.singapore
  bucket   = aws_s3_bucket.secondary.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "primary" {
  bucket = aws_s3_bucket.primary.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "secondary" {
  provider = aws.singapore
  bucket   = aws_s3_bucket.secondary.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
