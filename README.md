# Ofisy — infraestrutura de bancos

Um repositório, cinco raízes e cinco states independentes, conforme
[ADR-0013](https://github.com/15SOAT-FIAP/techchallenge-ofisy/blob/12e511c86ad9243837c2429ef508fa8de7939f94/docs/adr/0013-utilizar-dynamodb-no-ms-ofisy-notification.md)
e [ADR-0014](https://github.com/15SOAT-FIAP/techchallenge-ofisy/blob/12e511c86ad9243837c2429ef508fa8de7939f94/docs/adr/0014-manter-a-infraestrutura-de-bancos-em-um-unico-repositorio.md).
O ambiente AWS é **efêmero**: é válido que nenhum banco ou cluster esteja provisionado.
O bucket existente sobrevive ao ciclo do ambiente; cada serviço tem deploy/destroy próprio.

| Raiz | Recurso / banco | Chave S3 |
|---|---|---|
| `core/` | RDS `ofisy-postgres-db` / `ofisydb` | `rds/terraform.tfstate` (preservada) |
| `billing/` | RDS `ofisy-billing-postgres-db` / `ofisy_billing` | `databases/billing/terraform.tfstate` |
| `stock/` | RDS `ofisy-stock-postgres-db` / `ofisy_stock` | `databases/stock/terraform.tfstate` |
| `execution/` | RDS `ofisy-execution-postgres-db` / `ofisy_execution` | `databases/execution/terraform.tfstate` |
| `notification/` | DynamoDB `Notifications` | `databases/notification/terraform.tfstate` |

As quatro raízes PostgreSQL usam `modules/postgresql/`. Alterações no módulo exigem
validação/plan nas quatro raízes e um deploy próprio para cada banco. Não usar `-target`
para separar serviços. O core preserva parâmetros e seis outputs do RDS legado.
Antes de operar sobre um state existente, leia o [procedimento de migração](docs/migration-core.md).

## Subida e desmontagem do ambiente

1. Subir rede, EKS e SGs de origem no [eks-infra](https://github.com/15SOAT-FIAP/techchallenge-ofisy-eks-infra).
2. Subir somente os bancos necessários. Os RDS descobrem `ofisy-vpc`, subnets
   `ofisy-private-subnet-*`, `ofisy-eks-sg` e o SG dos nós do `ofisy-cluster`.
3. Core também libera `ofisy-lambda-auth-sg`, criado pela rede. A Lambda de autenticação
   deve ser provisionada depois do core; os outros bancos não dependem dela.
4. Configurar aplicações com credenciais/endpoints e iniciar os consumidores.

A criação da tabela DynamoDB não depende da VPC/EKS; sua aplicação precisa de rede e IAM.
Para desmontar, parar consumidores/aplicações, remover dependências como a Lambda antes
do core, destruir cada banco necessário pelo workflow próprio e só então remover rede/EKS.
O bucket não é criado nem destruído por essas raízes. As instâncias mantêm a política
legada `skip_final_snapshot = true`, sem `prevent_destroy`: o destroy autorizado apaga
dados, portanto backups necessários devem ser tratados antes da desmontagem.

Os SGs de origem são do `eks-infra`; o SG de cada RDS e suas regras permanecem neste
repositório. A [divergência textual com a ADR-0014](docs/migration-core.md) é documentada:
transferir a propriedade do SG legado exige alteração coordenada em dois states.

## Contrato de notification

Referência: `origin/stack/06-rest-api`,
[`8d6cba50dfcd03ff5c8fed07dc17ad407a0bcbb3`](https://github.com/15SOAT-FIAP/ms-ofisy-notification/tree/8d6cba50dfcd03ff5c8fed07dc17ad407a0bcbb3).
A persistência ainda está na stack de PRs; não está no `master` de notification.

- `Notifications`, capacidade `PAY_PER_REQUEST`, partition key `id` String.
- `TypeIndex`: partition key `type` String, sort key `createdAt` String, projeção `ALL`.
- `ReferenceIdIndex`: partition key `referenceId` String, projeção `ALL`.
- `read` é booleano comum filtrado na consulta por tipo; o código não usa índice separado
  para leitura. `message` e `updatedAt` também não são chaves.
- Categorias `LOW_STOCK` e `QUOTE_GENERATED` preservadas. GSIs têm consistência eventual.
- Sem TTL: não há retenção definida nem atributo de expiração no serviço.
- Outputs `table_name`, `table_arn` e `index_arns` para integração com runtime/IAM.

Mensageria, permissões da identidade da aplicação e migração PostgreSQL → DynamoDB
não são provisionadas neste PR.

## Validação sem ambiente AWS

Terraform >= 1.11 (testes usam `state_key`), Node.js >= 20, Docker para integração local.
CI fixa Terraform 1.15.7 e LocalStack 4.9.0; lockfiles fixam AWS provider 5.100.0.

```sh
terraform fmt -check -recursive
terraform -chdir=core init -backend=false -input=false -lockfile=readonly
terraform -chdir=core validate
terraform -chdir=core test -json -verbose > core-tests.jsonl
node scripts/assert-test-report.cjs core-tests.jsonl core
node --test scripts/check-core-plan.test.cjs
```

Repetir init/validate/test por raiz. Os testes usam provider **mock**, inclusive o `apply`
do ensaio legado, que cria apenas state simulado. O gate exige sete movimentos `no-op`
no core e falha com testes ausentes, erros ou skips. A integração gera a definição da
tabela a partir do state Terraform simulado e a cria em LocalStack: GetItem, dois GSIs,
projeção, categorias, ordenação, paginação, leitura e inserção condicional idempotente.

## Configuração e plan AWS

O backend usa o bucket existente `ofisy-tfstate-<account_id>`, `us-east-1`. Cada raiz fixa
sua chave e ativa lock nativo S3 (`use_lockfile`), que requer permissões sobre o objeto
`.tflock`. Os exemplos `backend.hcl.example` recebem somente bucket e região.
Nunca versionar state, senhas, tfvars reais ou planos; planos/state podem conter segredos.

Para plan quando houver ambiente AWS disponível, copiar o exemplo para `core/backend.hcl`,
informar `TF_VAR_account_id` e a senha vigente em `TF_VAR_db_password`:

```sh
terraform -chdir=core init -backend-config=backend.hcl -lockfile=readonly
terraform -chdir=core plan -out=operation.tfplan
terraform -chdir=core show -json operation.tfplan > core/plan.json
node scripts/check-core-plan.cjs core/plan.json
```

O gate permite criação em ambiente vazio e impede exclusão/substituição no deploy do core.
Se o RDS existe e o state não foi localizado, recuperar o state correto antes de operar.
Não trocar a chave nem criar outro state para contornar esse cenário.

## Workflows

Cada serviço tem `plan-<serviço>.yml`, `deploy-<serviço>.yml`, `destroy-<serviço>.yml`.
A execução compartilhada está em `database-operation.yml`.

- `validate.yml`: automático em PR e push em master; cinco raízes sem credenciais AWS,
  ensaio de migração e integração DynamoDB local. Uma alteração no módulo é testada nos
  quatro serviços PostgreSQL, mesmo sem ambiente de pé.
- Plan AWS: **manual**, selecionando o workflow do serviço e a branch. Não exige AWS
  permanentemente disponível para validar PRs. Os RDS dependem da rede/EKS para esse plan.
- Deploy: manual e somente `master`; gera e aplica exatamente o plano salvo.
- Destroy: manual e somente `master`, exige digitar o nome exato do serviço; aplica plano
  de destruição salvo. Não existe destroy conjunto dos cinco bancos.
- Plan/deploy/destroy compartilham concorrência `database-<serviço>`, sem cancelamento,
  além do lock S3. Isolamento de state não equivale a isolamento de permissões IAM.
- Não há criação automática de bucket. Plan é apresentado no resumo do run, sem upload
  de binário nem comentário automático no PR. Nenhum workflow AWS é disparado por este PR.

Secrets em `AWS_ACADEMY` ou herdados da organização:

| Secret | Uso |
|---|---|
| `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_SESSION_TOKEN` | Sessão AWS Academy |
| `AWS_ACCOUNT_ID` | Conta esperada e sufixo do bucket |
| `DB_PASSWORD` | Senha atual do core, preservada |
| `DB_PASSWORD_BILLING` | Senha billing |
| `DB_PASSWORD_STOCK` | Senha stock |
| `DB_PASSWORD_EXECUTION` | Senha execution |

Notification não exige senha. As senhas entram por variáveis de ambiente, sem gravar HCL.
Não é necessário executar apply/destroy na AWS para validar ou revisar esta alteração.
