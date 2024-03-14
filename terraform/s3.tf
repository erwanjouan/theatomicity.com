resource "aws_s3_bucket" "redirect" {
  // redirect https://theatomicity.com -> https://www.theatomicity.com
  bucket = local.domains[0]
  acl    = "public-read"
  website {
    redirect_all_requests_to = local.www_domain
  }
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_s3_bucket" "main" {
  // main https://www.theatomicity.com
  bucket = local.domains[1]
  acl    = "public-read"
  website {
    index_document = "index.html"
    error_document = "error.html"
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

/*
resource "aws_s3_bucket_policy" "s3_oais" {
  count  = length(local.domains)
  bucket = local.domains[count.index]
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::${local.domains[count.index]}/*",
      "Principal": {
        "AWS": "${aws_cloudfront_origin_access_identity.this.iam_arn}"
      }
    }
  ]
}
POLICY
}
*/

resource "aws_s3_bucket_object" "private_index" {
  bucket        = aws_s3_bucket.main.id
  acl           = "public-read"
  key           = "private/index.html"
  content       = templatefile("${path.module}/../www/private/index.html", { buckets = var.www_buckets })
  content_type  = "text/html"
  storage_class = "REDUCED_REDUNDANCY"
  cache_control = "public, max-age=3600"
}


resource "aws_s3_bucket_object" "error_page" {
  bucket        = aws_s3_bucket.main.id
  key           = "error.html"
  acl           = "public-read"
  content       = <<HTML
<!DOCTYPE html>
<html>
    <body>
        Oups, this is the error page !!
    </body>
</html>
HTML
  content_type  = "text/html"
  storage_class = "REDUCED_REDUNDANCY"
  cache_control = "public, max-age=3600"
}

module "template_files" {
  source   = "hashicorp/dir/template"
  base_dir = "www"
}

resource "aws_s3_bucket_object" "static_files" {
  for_each     = module.template_files.files
  bucket       = aws_s3_bucket.main.id
  acl          = "public-read"
  key          = replace(each.value.source_path, "www/", "")
  content_type = each.value.content_type
  source       = each.value.source_path
  etag         = each.value.digests.md5
}
