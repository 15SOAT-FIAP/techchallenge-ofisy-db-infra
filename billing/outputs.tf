output "rds_endpoint" {
  value = module.postgresql.rds_endpoint
}
output "rds_address" {
  value = module.postgresql.rds_address
}
output "rds_port" {
  value = module.postgresql.rds_port
}
output "rds_database_name" {
  value = module.postgresql.rds_database_name
}
output "rds_username" {
  value     = module.postgresql.rds_username
  sensitive = true
}
output "rds_security_group_id" {
  value = module.postgresql.rds_security_group_id
}
