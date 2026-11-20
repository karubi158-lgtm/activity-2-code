# Shareable dashboard: one Lambda behind an HTTPS Function URL serves the page + API.
# Data access is gated by a shared access code.
data "archive_file" "api" {
  type        = "zip"
  source_dir  = "${path.root}/../dashboard"
  excludes    = ["package-lock.json", ".gitignore"]
  output_path = "${path.root}/.build/api.zip"
}

resource "aws_iam_role" "api" {
  provider = aws.a
  name     = "${var.bucket_prefix}-dashboard-api"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "api_logs" {
  provider   = aws.a
  role       = aws_iam_role.api.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "api_s3" {
  provider = aws.a
  role     = aws_iam_role.api.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = ["s3:ListBucket", "s3:GetObject", "s3:PutObject", "s3:DeleteObject", "s3:DeleteObjectVersion", "s3:ListBucketVersions"]
      Resource = [
        "arn:aws:s3:::${local.bucket_a}", "arn:aws:s3:::${local.bucket_a}/*",
        "arn:aws:s3:::${local.bucket_b}", "arn:aws:s3:::${local.bucket_b}/*",
      ]
    }]
  })
}

resource "aws_lambda_function" "api" {
  provider         = aws.a
  function_name    = "${var.bucket_prefix}-dashboard"
  role             = aws_iam_role.api.arn
  runtime          = "nodejs20.x"
  handler          = "handler.handler"
  filename         = data.archive_file.api.output_path
  source_code_hash = data.archive_file.api.output_base64sha256
  timeout          = 30
  memory_size      = 256

  environment {
    variables = {
      BUCKET_A    = local.bucket_a
      REGION_A    = var.region_a
      BUCKET_B    = local.bucket_b
      REGION_B    = var.region_b
      ACCESS_CODE = var.access_code
    }
  }
}

resource "aws_lambda_function_url" "api" {
  provider           = aws.a
  function_name      = aws_lambda_function.api.function_name
  authorization_type = "NONE"
}

resource "aws_lambda_permission" "url" {
  provider               = aws.a
  statement_id           = "FunctionURLAllowPublicAccess"
  action                 = "lambda:InvokeFunctionUrl"
  function_name          = aws_lambda_function.api.function_name
  principal              = "*"
  function_url_auth_type = "NONE"
}

resource "aws_lambda_permission" "url_invoke" {
  provider      = aws.a
  statement_id  = "FunctionURLInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api.function_name
  principal     = "*"
}
