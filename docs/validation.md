# Validação da implementação

Data: 29/10/2026. Ambiente AWS considerado efêmero.

## Fontes inspecionadas após fetch da origin

- db-infra: `origin/master`, `82beaca047293e739a4167b700392dfb5c2c0bdd`, base mais
  recente por data/ancestralidade; nenhum PR aberto na inspeção inicial.
- Core/ADRs: `origin/master`, `12e511c86ad9243837c2429ef508fa8de7939f94`.
- Notification: `origin/stack/06-rest-api`, `8d6cba50dfcd03ff5c8fed07dc17ad407a0bcbb3`,
  topo da stack que contém persistência, SQS, segurança e REST. Contrato confirmado em
  `DynamoDbNotificationEntity`, `DynamoDbNotificationRepositoryImpl`, `application.yml`
  e `dev/integration/bootstrap.py`. PRs abertos: #20, #21, #22 e #23.
- EKS/rede: `origin/master`, `bd821b42e2cfd22775ee49ea5fe170e7dc52ca0e`.

## Resultados locais

| Verificação | Resultado |
|---|---|
| Terraform 1.15.7 / AWS provider 5.100.0 | Versões utilizadas e provider fixado nas cinco raízes |
| `terraform fmt -check -recursive` | Aprovado |
| `terraform validate` | Cinco raízes aprovadas |
| `terraform test` com mocks | Core 3; billing 1; stock 1; execution 1; notification 1 |
| Gate do ensaio de migração | Sete recursos `no-op`, com `previous_address`; zero criação/alteração/exclusão |
| Gates Node.js | Seis testes aprovados, incluindo skip/evidência ausente/substituição |
| Smoke DynamoDB / LocalStack 4.9.0 | Aprovado com schema extraído do state Terraform simulado |
| actionlint 1.7.12, sem shellcheck | Todos os workflows novos/alterados aprovados |
| `git diff --check` | Aprovado |

Sete execuções de teste Terraform e seis testes Node, sem falhas, erros ou skips na
execução final. O ensaio legado inclui um apply **do provider mock** e seu teardown
local; nenhuma dessas operações chama a AWS.

O smoke local cria `Notifications` em container exclusivo, insere as categorias
`LOW_STOCK`/`QUOTE_GENERATED` e verifica GetItem, ambos os GSIs, projeção ALL, ordenação,
paginação com LastEvaluatedKey, atualização/filtro de leitura e rejeição de duplicata
por inserção condicional. O cliente usa endpoint fixo `http://localhost:4566` dentro do
container e credenciais fictícias. Não é evidência de provisionamento ou integração AWS.

## Limitações e pendências operacionais

- Não foram lidos state remoto nem dados AWS. Nenhum plan/apply/destroy AWS foi executado.
  Um futuro plan remoto deve confirmar os movimentos e o estado real do ambiente.
- CI remoto deve ser conferido no SHA do PR; aprovação local não comprova CI remoto.
- O SG do RDS permanece no state atual; a divergência com a ADR-0014 e a transferência
  futura entre repositórios estão descritas em `migration-core.md`.
- Runtime IAM, mensageria, cutover e migração de registros não fazem parte desta mudança.
- O lint completo do repositório aponta uso de título de PR diretamente em shell no
  workflow legado e inalterado `notify-pr.yml`; esse arquivo não foi modificado.
