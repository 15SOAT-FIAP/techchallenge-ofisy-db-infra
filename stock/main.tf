terraform {
  required_version = ">= 1.11.0"
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
  }
}
provider "aws" {
  region              = "us-east-1"
  allowed_account_ids = var.account_id == "" ? null : [var.account_id]
}
module "postgresql" {
  source             = "../modules/postgresql"
  name_prefix        = "ofisy-stock"
  database_name      = "ofisy_stock"
  db_password        = var.db_password
  vpc_id             = var.vpc_id
  private_subnet_ids = var.private_subnet_ids
  allow_lambda_auth  = false
}
