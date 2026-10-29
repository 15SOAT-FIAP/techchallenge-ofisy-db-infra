mock_provider "aws" {}
run "notification_contract" {
  command = apply
  assert {
    condition     = aws_dynamodb_table.notifications.name == "Notifications" && aws_dynamodb_table.notifications.billing_mode == "PAY_PER_REQUEST" && aws_dynamodb_table.notifications.hash_key == "id" && aws_dynamodb_table.notifications.range_key == null
    error_message = "Nome, capacidade e chave devem corresponder ao serviço."
  }
  assert {
    condition     = length(aws_dynamodb_table.notifications.global_secondary_index) == 2 && alltrue([for i in aws_dynamodb_table.notifications.global_secondary_index : i.projection_type == "ALL" && (i.name == "TypeIndex" ? i.hash_key == "type" && i.range_key == "createdAt" : i.name == "ReferenceIdIndex" && i.hash_key == "referenceId" && (i.range_key == null || i.range_key == ""))])
    error_message = "Índices incompatíveis com o gateway e o bootstrap atuais."
  }
  assert {
    condition     = length(aws_dynamodb_table.notifications.attribute) == 4 && alltrue([for a in aws_dynamodb_table.notifications.attribute : a.type == "S" && contains(["id", "type", "createdAt", "referenceId"], a.name)])
    error_message = "Apenas atributos das chaves são declarados, todos String."
  }
  assert {
    condition     = alltrue([for ttl in aws_dynamodb_table.notifications.ttl : !ttl.enabled])
    error_message = "Não há política de expiração aprovada."
  }
}
