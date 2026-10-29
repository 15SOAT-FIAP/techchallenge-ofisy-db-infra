mock_provider "aws" {
  mock_data "aws_vpc" { defaults = { id = "vpc-00000000000000001" } }
  mock_data "aws_subnets" { defaults = { ids = ["subnet-00000000000000001", "subnet-00000000000000002"] } }
  mock_data "aws_security_group" { defaults = { id = "sg-00000000000000001" } }
  mock_data "aws_eks_cluster" {
    defaults = { vpc_config = [{ cluster_security_group_id = "sg-00000000000000002" }] }
  }
}
variables { db_password = "LocalTestPassword123!" }
run "service_contract" {
  command = plan
  assert {
    condition     = module.postgresql.rds_database_name == "ofisy_billing"
    error_message = "Nome do banco incompatível com a raiz."
  }
}
