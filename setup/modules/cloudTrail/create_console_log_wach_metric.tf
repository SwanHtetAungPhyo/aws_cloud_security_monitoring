resource "aws_cloudwatch_log_metric_filter" "console_login_no_mfa" {
  name           = "ConsoleLoginWithoutMFA"
  log_group_name = aws_cloudwatch_log_group.cloudtrail_log_group.name
  pattern        = "{ $.eventName = \"ConsoleLogin\" && $.additionalEventData.MFAUsed = \"No\" }"

  metric_transformation {
    name          = "ConsoleLoginWithoutMFA"
    namespace     = "SecurityMetrics"
    value         = "1"
    default_value = "0"
  }
}

resource "aws_cloudwatch_metric_alarm" "console_login_no_mfa" {
  alarm_name          = "ConsoleLoginWithoutMFA"
  alarm_description   = "Someone logged into console without MFA"
  metric_name         = "ConsoleLoginWithoutMFA"
  namespace           = "SecurityMetrics"
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.security_alerts.arn]
  tags                = var.tags
}
