"""Run INSIDE the dedicated LocalStack container, never against AWS.

Schema comes from the Terraform mock state, not a second table definition.
Consumer contract: ms-ofisy-notification / stack/06-rest-api @ 8d6cba5.
"""
import json
import sys
import time
import boto3
from botocore.exceptions import ClientError

client = boto3.client("dynamodb", endpoint_url="http://localhost:4566",
                      region_name="us-east-1", aws_access_key_id="test",
                      aws_secret_access_key="test")
with open(sys.argv[1], encoding="utf-8") as handle:
    spec = json.load(handle)
assert spec["TableName"] == "Notifications"
for attempt in range(30):
    try:
        client.list_tables()
        break
    except Exception:
        if attempt == 29:
            raise
        time.sleep(1)
client.create_table(**spec)
client.get_waiter("table_exists").wait(TableName=spec["TableName"])
table = spec["TableName"]
items = [
    {"id": {"S": "event-1"}, "type": {"S": "LOW_STOCK"}, "createdAt": {"S": "2026-10-29T10:00:00"},
     "referenceId": {"S": "stock-1"}, "read": {"BOOL": False}, "message": {"S": "Estoque baixo"}},
    {"id": {"S": "event-2"}, "type": {"S": "LOW_STOCK"}, "createdAt": {"S": "2026-10-29T11:00:00"},
     "referenceId": {"S": "stock-2"}, "read": {"BOOL": False}, "message": {"S": "Estoque baixo"}},
    {"id": {"S": "event-3"}, "type": {"S": "QUOTE_GENERATED"}, "createdAt": {"S": "2026-10-29T12:00:00"},
     "referenceId": {"S": "quote-1"}, "read": {"BOOL": False}, "message": {"S": "Orçamento gerado"}},
]
for item in items:
    client.put_item(TableName=table, Item=item, ConditionExpression="attribute_not_exists(id)")
try:
    client.put_item(TableName=table, Item=items[0], ConditionExpression="attribute_not_exists(id)")
    raise AssertionError("Inserção duplicada aceita")
except ClientError as error:
    assert error.response["Error"]["Code"] == "ConditionalCheckFailedException"
assert client.get_item(TableName=table, Key={"id": {"S": "event-1"}}, ConsistentRead=True)["Item"] == items[0]
query = dict(TableName=table, IndexName="TypeIndex", KeyConditionExpression="#t = :t",
             ExpressionAttributeNames={"#t": "type"}, ExpressionAttributeValues={":t": {"S": "LOW_STOCK"}},
             ScanIndexForward=False, Limit=1)
page = client.query(**query)
assert page["Items"][0]["id"]["S"] == "event-2"
assert page["Items"][0]["message"]["S"] == "Estoque baixo"  # ALL projection
next_page = client.query(**query, ExclusiveStartKey=page["LastEvaluatedKey"])
assert next_page["Items"][0]["id"]["S"] == "event-1"
client.update_item(TableName=table, Key={"id": {"S": "event-2"}},
                   UpdateExpression="SET #r = :r", ExpressionAttributeNames={"#r": "read"},
                   ExpressionAttributeValues={":r": {"BOOL": True}})
unread = client.query(TableName=table, IndexName="TypeIndex", KeyConditionExpression="#t = :t",
                      FilterExpression="#r = :r", ExpressionAttributeNames={"#t": "type", "#r": "read"},
                      ExpressionAttributeValues={":t": {"S": "LOW_STOCK"}, ":r": {"BOOL": False}})
assert [i["id"]["S"] for i in unread["Items"]] == ["event-1"]
reference = client.query(TableName=table, IndexName="ReferenceIdIndex",
                         KeyConditionExpression="referenceId = :ref",
                         ExpressionAttributeValues={":ref": {"S": "quote-1"}})
assert reference["Items"][0] == items[2]
print("PASS: schema Terraform, ambas as categorias, GetItem, dois GSIs/ALL, ordenação, paginação, leitura e idempotência")
