
data "archive_file" "lambda_package" {
  type        = "zip"
  source_file = "${path.module}/lambda/storage_health_check.py"
  output_path = "${path.module}/lambda/storage_health_check.zip"
}

resource "aws_iam_role" "lambda_role" {
  name = "${var.project_name}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "lambda_policy" {
  name = "${var.project_name}-lambda-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ]
        Resource = [
          aws_s3_bucket.primary.arn,
          aws_s3_bucket.secondary.arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = aws_sns_topic.alerts.arn
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${var.primary_region}:${data.aws_caller_identity.current.account_id}:*"
      }
    ]
  })
}

resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${var.project_name}-health-check"
  retention_in_days = 7
}

resource "aws_lambda_function" "health_check" {
  function_name = "${var.project_name}-health-check"
  role          = aws_iam_role.lambda_role.arn
  handler       = "storage_health_check.lambda_handler"
  runtime       = "python3.12"

  filename         = data.archive_file.lambda_package.output_path
  source_code_hash = data.archive_file.lambda_package.output_base64sha256
  timeout          = 30

  environment {
    variables = {
      PRIMARY_BUCKET   = aws_s3_bucket.primary.bucket
      SECONDARY_BUCKET = aws_s3_bucket.secondary.bucket
      SNS_TOPIC_ARN    = aws_sns_topic.alerts.arn
    }
  }

  depends_on = [
    aws_iam_role_policy.lambda_policy,
    aws_cloudwatch_log_group.lambda_logs
  ]
}

resource "aws_cloudwatch_event_rule" "health_schedule" {
  name                = "${var.project_name}-health-schedule"
  description         = "Run storage health check every five minutes"
  schedule_expression = "rate(5 minutes)"
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.health_schedule.name
  target_id = "StorageHealthCheck"
  arn       = aws_lambda_function.health_check.arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.health_check.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.health_schedule.arn
}
