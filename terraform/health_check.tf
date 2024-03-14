resource "aws_route53_health_check" "health_check" {
  count             = var.enable_health_check ? 1 : 0
  fqdn              = local.www_domain
  port              = 80
  type              = "HTTP"
  resource_path     = "/"
  failure_threshold = "3"
  request_interval  = "30"

  tags = {
    Name = local.www_domain
  }

  depends_on = [
    aws_route53_record.A,
  ]
}

resource "aws_cloudwatch_metric_alarm" "health_check_alarm" {
  count               = var.enable_health_check ? 1 : 0
  alarm_name          = "${local.www_domain}-health-check"
  provider            = aws.cloudfront
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "HealthCheckStatus"
  namespace           = "AWS/Route53"
  period              = "60"
  statistic           = "Minimum"
  threshold           = "1.0"
  alarm_description   = "This metric monitors the health of the endpoint"

  #ok_actions          = "${var.health_check_alarm_sns_topics}"
  #alarm_actions       = "${var.health_check_alarm_sns_topics}"
  treat_missing_data = "breaching"

  dimensions = {
    HealthCheckId = aws_route53_health_check.health_check[count.index].id
  }
}
