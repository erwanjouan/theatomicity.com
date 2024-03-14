data "aws_route53_zone" "zone" {
  name = "${var.domain}."
}

resource "aws_route53_record" "A" {
  count   = length(local.domains)
  zone_id = data.aws_route53_zone.zone.zone_id
  name    = element(local.domains, count.index)
  type    = "A"

  alias {
    name                   = element(aws_cloudfront_distribution.this.*.domain_name, count.index)
    zone_id                = element(aws_cloudfront_distribution.this.*.hosted_zone_id, count.index)
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "AAAA" {
  count   = length(local.domains)
  zone_id = data.aws_route53_zone.zone.zone_id
  name    = element(local.domains, count.index)
  type    = "AAAA"

  alias {
    name                   = element(aws_cloudfront_distribution.this.*.domain_name, count.index)
    zone_id                = element(aws_cloudfront_distribution.this.*.hosted_zone_id, count.index)
    evaluate_target_health = false
  }
}