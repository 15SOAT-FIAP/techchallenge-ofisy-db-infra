terraform {
  backend "s3" {
    key          = "databases/billing/terraform.tfstate"
    use_lockfile = true
  }
}
