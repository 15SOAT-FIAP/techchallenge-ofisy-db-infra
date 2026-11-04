variable "service" {
  description = "Nome do microsserviço dono do banco (ex.: stock). Define os nomes ms-ofisy-<service>-db e ms_ofisy_<service>_db"
  type        = string
}

variable "db_password" {
  description = "Senha do usuário administrativo do banco de dados PostgreSQL"
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.db_password) >= 8
    error_message = "A senha do banco de dados deve ter no mínimo 8 caracteres."
  }
}

variable "allow_lambda_auth" {
  description = "Libera acesso da Lambda de autenticação ao banco"
  type        = bool
  default     = false
}
