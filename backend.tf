terraform {
  backend "s3" {
    bucket  = "terraform-testapp-state"
    key     = "terraform/state"
    region  = "ap-southeast-2"
    encrypt = true
  }
}
