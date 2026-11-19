
output "mumbai_application_url" {
  description = "Primary application URL"
  value       = "http://${module.mumbai_app.alb_dns_name}"
}

output "singapore_application_url" {
  description = "Secondary application URL"
  value       = "http://${module.singapore_app.alb_dns_name}"
}

output "primary_s3_bucket" {
  value = aws_s3_bucket.primary.bucket
}

output "secondary_s3_bucket" {
  value = aws_s3_bucket.secondary.bucket
}

output "audit_s3_bucket" {
  value = aws_s3_bucket.cloudtrail_bucket.bucket
}

output "sns_topic_arn" {
  value = aws_sns_topic.alerts.arn
}

output "lambda_function_name" {
  value = aws_lambda_function.health_check.function_name
}

output "mumbai_target_group_arn" {
  value = module.mumbai_app.target_group_arn
}

output "singapore_target_group_arn" {
  value = module.singapore_app.target_group_arn
}

output "route53_application_url" {
  value = var.route53_domain_name == "" ? "Route 53 not configured" : "http://app.${trimsuffix(var.route53_domain_name, ".")}"
}
