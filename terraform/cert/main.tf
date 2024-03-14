provider "aws" {
  region = "eu-west-1"
}

# Additional provider configuration for east coast region (global)
provider "aws" {
  alias  = "cloudfront"
  region = "us-east-1"
}

terraform {
  backend "s3" {
    bucket = "20190208-mys3backend"
    key    = "www_cert/terraform.tfstate"
    region = "eu-west-1"
  }
}

