########################################
# SECURITY GROUP - RDS
########################################

# Cria um Security Group para controlar o acesso à instância RDS PostgreSQL.
resource "aws_security_group" "rds" {
  name        = "${local.name_prefix}-sg"
  description = "Security Group para o banco de dados RDS PostgreSQL"
  vpc_id      = data.aws_vpc.main.id

  tags = {
    Name = "${local.name_prefix}-sg"
  }
}

# Permite conexões PostgreSQL de dentro da VPC (nós dos clusters EKS).
# Liberar pelo CIDR, e não pelo Security Group do cluster, deixa o banco
# independente do ciclo de vida do cluster: recriar um cluster gera um SG novo.
resource "aws_security_group_rule" "rds_postgres_from_vpc" {
  type              = "ingress"
  from_port         = 5432
  to_port           = 5432
  protocol          = "tcp"
  cidr_blocks       = [data.aws_vpc.main.cidr_block]
  security_group_id = aws_security_group.rds.id
}

# Permite conexões PostgreSQL provenientes da Lambda de autenticação de clientes.
resource "aws_security_group_rule" "rds_postgres_from_lambda_auth" {
  count = var.allow_lambda_auth ? 1 : 0

  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = data.aws_security_group.lambda_auth[0].id
  security_group_id        = aws_security_group.rds.id
}

