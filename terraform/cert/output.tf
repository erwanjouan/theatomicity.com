output "aws_acm_certificate_ssl" {
  value = join(",", aws_acm_certificate.ssl.*.arn)
}