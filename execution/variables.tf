variable "db_password" {
  description = "Senha do usuário administrativo do banco de dados PostgreSQL"
  type        = string
  sensitive   = true
}
