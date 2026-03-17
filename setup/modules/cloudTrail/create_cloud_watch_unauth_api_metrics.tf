resource "aws_cloudwatch_log_metric_filter" "unauthorized_api_calls" {
  name           = "UnauthorizedAPICalls"
  log_group_name = aws_cloudwatch_log_group.cloudtrail_log_group.name
  pattern        = "{ $.errorCode = \"AccessDenied\" || $.errorCode = \"UnauthorizedAccess\" }"

  metric_transformation {
    name          = "UnauthorizedAPICalls"
    namespace     = "SecurityMetrics"
    value         = "1"
    default_value = "0"
  }
}

resource "aws_cloudwatch_metric_alarm" "unauthorized_api_calls" {
  alarm_name          = "UnauthorizedAPICalls"
  alarm_description   = "Fires when any AccessDenied or UnauthorizedAccess error occurs"
  metric_name         = "UnauthorizedAPICalls"
  namespace           = "SecurityMetrics"
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.security_alerts.arn]
  ok_actions          = [aws_sns_topic.security_alerts.arn]
  tags                = var.tags
}
