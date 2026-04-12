locals {
  static_files = fileset("${path.module}/site", "**")
}

resource "scaleway_object_bucket" "website" {
  name  = "20260412-my-tf-test-bucket"
  tags = {
    Name = "My bucket"
  }
}

resource "scaleway_object" "some_file" {
  bucket   = scaleway_object_bucket.website.id
  for_each = local.static_files
  key      = each.key
  file     = "${path.module}/site/${each.key}"
}