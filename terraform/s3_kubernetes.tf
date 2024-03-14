data "aws_s3_bucket" "origin" {
  for_each = toset(var.www_buckets)
  bucket   = each.key
}


resource "aws_s3_bucket_policy" "origin" {
  for_each = toset(var.www_buckets)
  bucket   = each.key
  policy   = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::${each.key}/*",
      "Principal": {
        "AWS": "${aws_cloudfront_origin_access_identity.this.iam_arn}"
      }
    }
  ]
}
POLICY
}