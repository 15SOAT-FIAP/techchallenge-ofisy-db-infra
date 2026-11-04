########################################
# DB SUBNET GROUP
########################################

# DB Subnet Group exigido pelo RDS em subnets privadas de pelo menos 2 AZs
resource "aws_db_subnet_group" "main" {
  name       = "${local.name_prefix}-subnet-group"
  subnet_ids = data.aws_subnets.private.ids

  tags = {
    Name = "${local.name_prefix}-subnet-group"
  }
}

########################################
# RDS POSTGRESQL DATABASE
########################################

# Instância Amazon RDS PostgreSQL gerenciada
resource "aws_db_instance" "main" {
  identifier             = local.name_prefix
  allocated_storage      = 20
  storage_type           = "gp2"
  engine                 = "postgres"
  engine_version         = "15"
  instance_class         = "db.t3.micro"
  username               = "admin_db"
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  db_name = local.database_name

  # Ambiente efêmero (AWS Academy): sem backups automáticos para subir/destruir mais rápido
  backup_retention_period = 0

  skip_final_snapshot = true
  multi_az            = false
  publicly_accessible = false
  storage_encrypted   = true

  tags = {
    Name    = local.name_prefix
    Service = "ms-ofisy-${var.service}"
  }
}
