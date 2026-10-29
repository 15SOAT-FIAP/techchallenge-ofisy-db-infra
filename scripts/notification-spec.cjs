const fs = require('node:fs');
const entries = fs.readFileSync(process.argv[2], 'utf8').trim().split(/\r?\n/).map(JSON.parse);
const state = entries.find(e => e.type === 'test_state' && e['@testrun'] === 'notification_contract')?.test_state;
const resource = state?.root_module?.resources?.find(r => r.address === 'aws_dynamodb_table.notifications');
if (!resource) throw new Error('Tabela ausente no resultado Terraform');
const v = resource.values;
const key = (hash, range) => [{AttributeName: hash, KeyType: 'HASH'}, ...(range ? [{AttributeName: range, KeyType: 'RANGE'}] : [])];
const spec = {
  TableName: v.name,
  BillingMode: v.billing_mode,
  AttributeDefinitions: v.attribute.map(a => ({AttributeName: a.name, AttributeType: a.type})),
  KeySchema: key(v.hash_key, v.range_key),
  GlobalSecondaryIndexes: v.global_secondary_index.map(i => ({IndexName: i.name, KeySchema: key(i.hash_key, i.range_key), Projection: {ProjectionType: i.projection_type}}))
};
fs.writeFileSync(process.argv[3], JSON.stringify(spec, null, 2)+'\n', 'utf8');
