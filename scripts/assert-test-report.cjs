const fs = require('node:fs');
const assert = require('node:assert/strict');
function checkReport(entries, service) {
const summary = entries.find(e => e.type === 'test_summary')?.test_summary;
assert(summary && summary.status === 'pass' && summary.failed === 0 && summary.errored === 0 && summary.skipped === 0, 'Testes ausentes, falhos ou pulados');
if (service === 'core') {
  const plan = entries.find(e => e.type === 'test_plan' && e['@testrun'] === 'migration')?.test_plan;
  const resources = plan?.resource_changes?.filter(r => r.mode === 'managed');
  assert(resources?.length === 7, 'A migração deve preservar os sete recursos legados');
  assert(resources.every(r => r.previous_address && r.change.actions.length === 1 && r.change.actions[0] === 'no-op'), 'A migração deve conter somente movimentos sem alterações');
  console.log('Migração: sete recursos movidos, zero criação/alteração/exclusão.');
}
console.log(`${service}: ${summary.passed} testes, zero falhas/erros/skips.`);
}
module.exports = { checkReport };
if (require.main === module) {
  const [file, service] = process.argv.slice(2);
  checkReport(fs.readFileSync(file, 'utf8').trim().split(/\r?\n/).map(JSON.parse), service);
}
