output "rds_address" {
  description = "Hostname/Endereço da instância RDS PostgreSQL"
  value       = aws_db_instance.main.address
}
