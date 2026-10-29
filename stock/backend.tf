terraform {
  backend "s3" {
    key          = "databases/stock/terraform.tfstate"
    use_lockfile = true
  }
}
