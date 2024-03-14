variable "domain" {
  default = "theatomicity.com"
}

variable "index_page" {
  default = "index.html"
}

variable "error_page" {
  default = "error.html"
}

variable "enable_gzip" {
  default     = true
  description = "Whether to make CloudFront automatically compress content for web requests that include `Accept-Encoding: gzip` in the request header"
}

variable "enable_health_check" {
  default     = false
  description = "If true, it creates a Route53 health check that monitors the www endpoint and an alarm that triggers whenever it's not reachable. Please note this comes at an extra monthly cost on your AWS account"
}

variable "lambda_file_name" {
  description = "lambda source file and archive file name"
}

variable "www_buckets" {
  type = list(string)
  default = [
    "20200708-kubernetes-up-running",
    "20200720-docker-up-and-running",
    "20200717-eks-workshop-notes",
    "20200723-sysops-diagram",
    "20200724-sysops-quizz",
    "20200724-kubernetes-resources",
    "20200730-electric",
    "20200824-indep",
    "20200823-tech-notes"
  ]
}

variable "public_website_bucket" {
  default = "20200901-the-atomicity"
}