# Garante que a tabela continua compatível com o ms-ofisy-notification
mock_provider "aws" {}

run "notification_contract" {
  command = plan

  assert {
    condition     = aws_dynamodb_table.notifications.name == "Notifications" && aws_dynamodb_table.notifications.hash_key == "id"
    error_message = "A tabela deve se chamar Notifications com chave id."
  }

  assert {
    condition = {
      for i in aws_dynamodb_table.notifications.global_secondary_index :
      i.name => [i.hash_key, i.range_key == null ? "" : i.range_key, i.projection_type]
      } == {
      TypeIndex        = ["type", "createdAt", "ALL"]
      ReferenceIdIndex = ["referenceId", "", "ALL"]
    }
    error_message = "Os índices devem ser TypeIndex (type/createdAt) e ReferenceIdIndex (referenceId), com projeção ALL."
  }
}
