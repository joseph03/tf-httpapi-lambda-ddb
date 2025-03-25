resource "aws_cloudwatch_log_metric_filter" "info_log_filter" {
  name           = "InfoLogFilter"
  log_group_name = aws_cloudwatch_log_group.http_api.name
  pattern        = "INFO"  #not sure why "[INFO]" cannot work
  
  metric_transformation {
    name      = "InfoLogCount"
    namespace = "${local.name_prefix}/Logs"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "info_log_alarm" {
  alarm_name                = "InfoLogCountExceeds10"
  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = 1
  metric_name               = "InfoLogCount"
  namespace                 = "${local.name_prefix}/Logs"
  period                    = 60
  statistic                 = "Sum"
  threshold                 = 10
  alarm_description         = "Alarm when INFO log count exceeds 10"
  alarm_actions             = [aws_sns_topic.email_alert.arn]
  ok_actions               = [aws_sns_topic.email_alert.arn]
}

resource "aws_sns_topic" "email_alert" {
  name = "sns-${local.name_prefix}-info-topic"
}

resource "aws_sns_topic_subscription" "email_subscription" {
  topic_arn = aws_sns_topic.email_alert.arn
  protocol  = "email"
  endpoint  = "joseph03sg@gmail.com"
}
