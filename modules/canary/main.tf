data "archive_file" "lambda_canary_zip" {
  type        = "zip"
  output_path = "${path.module}/lambda_canary.zip"  # Optional, to keep a local copy or use an S3 path
  source {
    content  = file("${path.module}/canary.js")  # Directly referencing the local canary.js file
    filename = "nodejs/node_modules/canary.js"
  }
}

resource "aws_synthetics_canary" "canary_api_calls" {
  name                 = var.name
  artifact_s3_location = "s3://${data.aws_s3_bucket.s3_canaries-reports.id}/"
  execution_role_arn   = data.aws_iam_role.role.arn
  runtime_version      = var.runtime_version
  handler              = "canary.handler"
  zip_file             = data.archive_file.lambda_canary_zip.output_path  # Reference the zip directly
  start_canary         = true

  success_retention_period = 2
  failure_retention_period = 14

  schedule {
    expression          = "rate(${var.frequency} minutes)"
    duration_in_seconds = 0
  }

  run_config {
    timeout_in_seconds = 15
    active_tracing     = false
  }

  vpc_config {
    subnet_ids         = var.subnet_ids
    security_group_ids = [var.security_group_id]
  }

  tags = {
    Name = "canary"
  }

  depends_on = [
    data.archive_file.lambda_canary_zip,
  ]

}

resource "aws_cloudwatch_metric_alarm" "canary_alarm" {
  alarm_name          = "canary-${var.name}"
  comparison_operator = "LessThanThreshold"
  period              = "300" // 5 minutes (should be calculated from the frequency of the canary)
  evaluation_periods  = "1"
  metric_name         = "SuccessPercent"
  namespace           = "CloudWatchSynthetics"
  statistic           = "Sum"
  datapoints_to_alarm = "1"
  threshold           = "90"
  alarm_actions       = [var.alert_sns_topic]
  alarm_description   = "Canary - ${var.name}"
  dimensions          = {
    CanaryName = var.name
  }
}