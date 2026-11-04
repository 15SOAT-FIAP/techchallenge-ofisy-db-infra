output "table_name" {
  value = aws_dynamodb_table.notifications.name
}

output "table_arn" {
  value = aws_dynamodb_table.notifications.arn
}
