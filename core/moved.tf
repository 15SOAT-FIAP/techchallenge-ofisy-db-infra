# Migração declarativa no MESMO state rds/terraform.tfstate. Não remover.
moved {
  from = aws_db_instance.main
  to   = module.postgresql.aws_db_instance.main
}
moved {
  from = aws_db_subnet_group.main
  to   = module.postgresql.aws_db_subnet_group.main
}
moved {
  from = aws_security_group.rds
  to   = module.postgresql.aws_security_group.rds
}
moved {
  from = aws_security_group_rule.rds_postgres_from_eks
  to   = module.postgresql.aws_security_group_rule.rds_postgres_from_eks
}
moved {
  from = aws_security_group_rule.rds_postgres_from_eks_nodes
  to   = module.postgresql.aws_security_group_rule.rds_postgres_from_eks_nodes
}
moved {
  from = aws_security_group_rule.rds_egress
  to   = module.postgresql.aws_security_group_rule.rds_egress
}
moved {
  from = aws_security_group_rule.rds_postgres_from_lambda_auth
  to   = module.postgresql.aws_security_group_rule.rds_postgres_from_lambda_auth[0]
}
