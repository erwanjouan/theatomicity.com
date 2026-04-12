terraform {
  backend "s3" {
    bucket = "20260411-atomicity-tfstate"
    key    = "terraform.tfstate"
    region = "fr-par"
    endpoint = "https://s3.fr-par.scw.cloud"
    skip_credentials_validation = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    use_path_style              = true
  }
}