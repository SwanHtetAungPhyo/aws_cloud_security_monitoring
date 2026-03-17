resource "aws_cloudwatch_log_metric_filter" "iam_policy_changes" {
  name           = "IAMPolicyChanges"
  log_group_name = aws_cloudwatch_log_group.cloudtrail_log_group.name
  pattern        = "{ $.eventName = \"DeleteGroupPolicy\" || $.eventName = \"DeleteRolePolicy\" || $.eventName = \"PutGroupPolicy\" || $.eventName = \"PutRolePolicy\" || $.eventName = \"AttachRolePolicy\" || $.eventName = \"DetachRolePolicy\" }"

  metric_transformation {
    name          = "IAMPolicyChanges"
    namespace     = "SecurityMetrics"
    value         = "1"
    default_value = "0"
  }
}

resource "aws_cloudwatch_metric_alarm" "iam_policy_changes" {
  alarm_name          = "IAMPolicyChanges"
  alarm_description   = "An IAM policy was attached, detached, or modified"
  metric_name         = "IAMPolicyChanges"
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
