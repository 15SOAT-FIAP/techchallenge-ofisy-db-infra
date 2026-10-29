terraform {
  backend "s3" {
    key          = "databases/execution/terraform.tfstate"
    use_lockfile = true
  }
}
