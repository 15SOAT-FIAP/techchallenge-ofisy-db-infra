const { test } = require('node:test');
const assert = require('node:assert/strict');
const { check } = require('./check-core-plan.cjs');
const plan = actions => ({ resource_changes: [{ mode: 'managed', address: 'module.postgresql.aws_db_instance.main', change: { actions } }] });
test('permite criação em ambiente efêmero e alterações não destrutivas', () => {
  for (const actions of [['create'], ['no-op'], ['update']]) assert.doesNotThrow(() => check(plan(actions)));
});
test('bloqueia exclusão e ambas as ordens de substituição', () => {
  for (const actions of [['delete'], ['delete','create'], ['create','delete']]) assert.throws(() => check(plan(actions)), /bloqueada/);
});
test('não aceita plano incompleto ou inválido', () => {
  for (const p of [{}, { ...plan(['create']), complete: false }, { ...plan(['create']), errored: true }]) assert.throws(() => check(p));
});
