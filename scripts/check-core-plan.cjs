const fs = require('node:fs');

function check(plan) {
  if (plan.errored || plan.complete === false || !Array.isArray(plan.resource_changes)) {
    throw new Error('Plano incompleto ou inválido.');
  }
  const destructive = plan.resource_changes.filter(change =>
    change.mode === 'managed' && change.change.actions.includes('delete'));
  if (destructive.length) {
    throw new Error('Core: exclusão/substituição bloqueada: ' + destructive.map(c => c.address).join(', '));
  }
}

module.exports = { check };
if (require.main === module) {
  check(JSON.parse(fs.readFileSync(process.argv[2], 'utf8')));
  console.log('Core: plano sem exclusão/substituição. Criação de ambiente efêmero permitida.');
}
