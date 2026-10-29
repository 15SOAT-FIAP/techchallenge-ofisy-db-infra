output "table_name" { value = aws_dynamodb_table.notifications.name }
output "table_arn" { value = aws_dynamodb_table.notifications.arn }
output "index_arns" {
  value = { for index in aws_dynamodb_table.notifications.global_secondary_index : index.name => "${aws_dynamodb_table.notifications.arn}/index/${index.name}" }
}
