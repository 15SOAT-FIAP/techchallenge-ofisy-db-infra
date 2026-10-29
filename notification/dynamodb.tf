resource "aws_dynamodb_table" "notifications" {
  name         = "Notifications"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"
  attribute {
    name = "id"
    type = "S"
  }
  attribute {
    name = "type"
    type = "S"
  }
  attribute {
    name = "createdAt"
    type = "S"
  }
  attribute {
    name = "referenceId"
    type = "S"
  }
  global_secondary_index {
    name            = "TypeIndex"
    hash_key        = "type"
    range_key       = "createdAt"
    projection_type = "ALL"
  }
  global_secondary_index {
    name            = "ReferenceIdIndex"
    hash_key        = "referenceId"
    projection_type = "ALL"
  }
  tags = { Name = "Notifications", Service = "notification" }
}
