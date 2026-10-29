terraform {
  backend "s3" {
    key          = "rds/terraform.tfstate"
    use_lockfile = true
  }
}
