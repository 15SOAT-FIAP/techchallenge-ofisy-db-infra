const { test } = require('node:test');
const assert = require('node:assert/strict');
const { checkReport } = require('./assert-test-report.cjs');
const summary = { type: 'test_summary', test_summary: {status:'pass', passed:3, failed:0, errored:0, skipped:0} };
const migration = {type:'test_plan', '@testrun':'migration', test_plan:{resource_changes:Array.from({length:7}, (_,i) => ({mode:'managed', previous_address:'legacy.'+i, change:{actions:['no-op']}}))}};
test('aceita evidência completa da migração', () => assert.doesNotThrow(() => checkReport([summary,migration], 'core')));
test('rejeita skips, falhas, erros e relatório ausente', () => {
  assert.throws(() => checkReport([], 'core'));
  for (const key of ['skipped','failed','errored']) assert.throws(() => checkReport([{...summary,test_summary:{...summary.test_summary,[key]:1}},migration], 'core'));
});
test('rejeita migração ausente, parcial ou com substituição', () => {
  assert.throws(() => checkReport([summary], 'core'));
  for (const resources of [migration.test_plan.resource_changes.slice(1), migration.test_plan.resource_changes.map((r,i) => i ? r : {...r,change:{actions:['delete','create']}})]) {
    assert.throws(() => checkReport([summary,{...migration,test_plan:{resource_changes:resources}}], 'core'));
  }
});
