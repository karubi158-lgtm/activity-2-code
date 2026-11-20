terraform {
  required_providers {
    aws     = { source = "hashicorp/aws" }
    archive = { source = "hashicorp/archive" }
  }
}

resource "aws_s3_bucket" "this" {
  bucket        = var.bucket_name
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket                  = aws_s3_bucket.this.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_cors_configuration" "this" {
  bucket = aws_s3_bucket.this.id
  cors_rule {
    allowed_origins = ["*"]
    allowed_methods = ["GET", "PUT", "POST", "DELETE", "HEAD"]
    allowed_headers = ["*"]
    expose_headers  = ["ETag"]
  }
}

# Send object events to EventBridge (default bus)
resource "aws_s3_bucket_notification" "this" {
  bucket      = aws_s3_bucket.this.id
  eventbridge = true
}

# ---------------- Lambda ----------------
data "archive_file" "healer" {
  type        = "zip"
  source_file = "${path.root}/lambda/healer.py"
  output_path = "${path.root}/.build/healer-${var.region}.zip"
}

resource "aws_iam_role" "healer" {
  name = "${var.bucket_name}-healer"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "logs" {
  role       = aws_iam_role.healer.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "s3" {
  role = aws_iam_role.healer.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "s3:ListBucket", "s3:GetBucketLocation", "s3:GetObject", "s3:GetObjectVersion",
        "s3:PutObject", "s3:DeleteObjectVersion"
      ]
      Resource = [
        "arn:aws:s3:::${var.bucket_name}", "arn:aws:s3:::${var.bucket_name}/*",
        "arn:aws:s3:::${var.peer_bucket_name}", "arn:aws:s3:::${var.peer_bucket_name}/*",
      ]
    }]
  })
}

resource "aws_lambda_function" "healer" {
  function_name    = "${var.bucket_name}-healer"
  role             = aws_iam_role.healer.arn
  runtime          = "python3.12"
  handler          = "healer.handler"
  filename         = data.archive_file.healer.output_path
  source_code_hash = data.archive_file.healer.output_base64sha256
  timeout          = 300
  memory_size      = 512

  environment {
    variables = {
      LOCAL_BUCKET = var.bucket_name
      LOCAL_REGION = var.region
      PEER_BUCKET  = var.peer_bucket_name
      PEER_REGION  = var.peer_region
    }
  }
}

# ---------------- EventBridge rules ----------------
locals {
  state = var.healing_enabled ? "ENABLED" : "DISABLED"
  rules = {
    objects = {
      description = "Object created/deleted in ${var.bucket_name}"
      pattern = jsonencode({
        source        = ["aws.s3"]
        "detail-type" = ["Object Created", "Object Deleted"]
        detail        = { bucket = { name = [var.bucket_name] } }
      })
      schedule = null
    }
    reconcile = {
      description = "Periodic full reconcile (safety net)"
      pattern     = null
      schedule    = var.reconcile_schedule
    }
  }
}

resource "aws_cloudwatch_event_rule" "r" {
  for_each            = local.rules
  name                = "${var.bucket_name}-${each.key}"
  description         = each.value.description
  event_pattern       = each.value.pattern
  schedule_expression = each.value.schedule
  state               = local.state
}

resource "aws_cloudwatch_event_target" "t" {
  for_each = local.rules
  rule     = aws_cloudwatch_event_rule.r[each.key].name
  arn      = aws_lambda_function.healer.arn
}

resource "aws_lambda_permission" "p" {
  for_each      = local.rules
  statement_id  = "events-${each.key}"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.healer.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.r[each.key].arn
}
