/*data "aws_acm_certificate" "ssl" {
  count    = length(local.domains)
  provider = aws.cloudfront // this is an AWS requirement
  domain   = local.www_domain
  statuses = ["ISSUED"]
}*/

resource "aws_acm_certificate" "ssl" {
  count             = length(local.domains)
  provider          = aws.cloudfront
  domain_name       = element(local.domains, count.index)
  validation_method = "DNS"
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "ssl" {
  count           = length(local.domains)
  provider        = aws.cloudfront
  certificate_arn = aws_acm_certificate.ssl[count.index].arn
  /*validation_record_fqdns = [
    aws_route53_record.A[count.index].fqdn,
    aws_route53_record.AAAA[count.index].fqdn
  ]*/
}