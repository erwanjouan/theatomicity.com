locals {
  www_domain = "www.${var.domain}"

  domains = [
    var.domain,
    local.www_domain,
  ]

}