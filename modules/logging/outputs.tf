output "cloudtrail_arn" {
  description = "ARN of the organization CloudTrail trail"
  value       = aws_cloudtrail.org_trail.arn
}

output "cloudtrail_id" {
  description = "Name of the CloudTrail trail"
  value       = aws_cloudtrail.org_trail.id
}

output "logging_bucket_arn" {
  description = "ARN of the centralized logging S3 bucket"
  value       = aws_s3_bucket.cloudtrail_logs.arn
}

output "logging_bucket_id" {
  description = "Name of the centralized logging S3 bucket"
  value       = aws_s3_bucket.cloudtrail_logs.id
}

output "kms_key_arn" {
  description = "ARN of the KMS key used for CloudTrail log encryption"
  value       = aws_kms_key.cloudtrail.arn
}

output "kms_key_id" {
  description = "ID of the KMS key used for CloudTrail log encryption"
  value       = aws_kms_key.cloudtrail.key_id
}

output "log_group_arn" {
  description = "ARN of the CloudWatch Log Group for CloudTrail"
  value       = aws_cloudwatch_log_group.cloudtrail.arn
}
