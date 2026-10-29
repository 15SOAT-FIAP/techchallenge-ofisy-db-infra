terraform {
  backend "s3" {
    key          = "databases/notification/terraform.tfstate"
    use_lockfile = true
  }
}
