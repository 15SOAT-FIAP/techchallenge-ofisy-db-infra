mock_provider "aws" {
  mock_data "aws_vpc" { defaults = { id = "vpc-00000000000000001" } }
  mock_data "aws_subnets" { defaults = { ids = ["subnet-00000000000000001", "subnet-00000000000000002"] } }
  mock_data "aws_security_group" { defaults = { id = "sg-00000000000000001" } }
  mock_data "aws_eks_cluster" {
    defaults = { vpc_config = [{ cluster_security_group_id = "sg-00000000000000002" }] }
  }
}
variables {
  account_id  = "123456789012"
  db_password = "LocalTestPassword123!"
}
run "legacy" {
  command   = apply
  state_key = "migration"
  module { source = "./tests/legacy" }
}
run "migration" {
  command   = plan
  state_key = "migration"
  assert {
    condition     = output.rds_database_name == run.legacy.rds_database_name && output.rds_address == run.legacy.rds_address && output.rds_security_group_id == run.legacy.rds_security_group_id
    error_message = "A migração precisa preservar banco, endereço e security group."
  }
}
