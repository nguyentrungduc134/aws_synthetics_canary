provider "aws" {
  region = "us-east-1"
}
resource "aws_synthetics_canary" "canary_api_calls" {
  name                 = var.name
  artifact_s3_location = "s3://${data.aws_s3_bucket.s3_canaries-reports.id}/"
  execution_role_arn   = data.aws_iam_role.role.arn
  runtime_version      = var.runtime_version
  handler              = "canary.handler"
  zip_file             = "${path.module}/lambda_canary.zip"
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
    environment_variables = {
      API_HOSTNAME    = var.api_hostname
      API_PATH        = var.api_path
      TAKE_SCREENSHOT = var.take_screenshot
    }    
  }

  #vpc_config {
  #  subnet_ids         = var.subnet_ids
  #  security_group_ids = [var.security_group_id]
  #}

  tags = {
    Name = "canary"
  }

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