# Migração da raiz legada para core

Base: `82beaca047293e739a4167b700392dfb5c2c0bdd`. O ambiente AWS é efêmero: pode estar
criado, destruído ou ainda não provisionado. Não se presume produção nem disponibilidade
permanente de RDS, EKS ou credenciais AWS Academy.

## Preservação

Permanecem o bucket `ofisy-tfstate-<account_id>`, região `us-east-1` e a chave
**`rds/terraform.tfstate`**, mesmo com a troca do diretório `infra/` por `core/`.
O RDS continua `ofisy-postgres-db`, banco `ofisydb`, usuário `ofisy`, PostgreSQL 15,
`db.t3.micro`, 20 GiB/gp2, criptografado e privado, com os mesmos backups e janelas.
Subnet group `ofisy-db-subnet-group`, SG `ofisy-rds-sg`, quatro regras e seis outputs
também são preservados. A senha vigente continua no secret `DB_PASSWORD`.

`core/moved.tf` mapeia os sete recursos para `module.postgresql`, incluindo `[0]` na regra
opcional da Lambda. Não remover os blocos enquanto existirem states legados. Não fazer
`state mv`, `state rm`, import nem cópia de objetos S3 para esta reorganização.

## Ambiente já provisionado

1. Conferir a conta, o bucket e a chave existentes antes de inicializar `core/`.
2. Guardar um backup restrito do state por procedimento operacional, sem versionar ou
   publicar: ele pode conter a senha do banco.
3. Inicializar `core/` com o mesmo bucket e fornecer a senha atual. Executar somente plan.
4. A reorganização isolada deve mostrar sete movimentos e **zero adições, alterações e
   exclusões**. Investigar drift ou outras alterações antes de prosseguir.
5. Uma futura execução autorizada de deploy registra os novos endereços no mesmo state.
   O workflow bloqueia exclusão/substituição do core. Este PR não executa isso na AWS.

Se o state estiver ausente mas o RDS existir, recuperar o state correto antes de operar;
um state novo não adota recursos existentes. Não alterar a chave para contornar o problema.

## Ambiente desmontado

Um state ausente após destruição legítima, ou vazio após destroy, é esperado. Depois da
rede/EKS, cada raiz pode criar seu banco. O gate permite `create`, sem exigir um banco
permanente. O bucket existente deve sobreviver ao ciclo do ambiente e existir antes do
init. Workflows de plan não criam buckets ou outros recursos AWS.

## Evidência local

`core/tests/legacy/` congela as definições do commit base. O ensaio cria state em memória
com provider **mock** e planeja a nova raiz sobre o mesmo state. O gate
`scripts/assert-test-report.cjs` exige sete recursos movidos e todos `no-op`, sem skips.
Isso não substitui um plan contra o state remoto real quando houver ambiente provisionado.

## Divergência com a ADR-0014: SG do RDS

O `eks-infra` em `bd821b42e2cfd22775ee49ea5fe170e7dc52ca0e` cria os SGs do EKS e da
Lambda; o `db-infra` legado cria o SG do RDS e suas regras. A ADR generaliza a propriedade
dos SGs para o repositório de rede. Este PR mantém a propriedade atual do SG do banco para
preservar seu state. SGs de origem continuam localizados por tag; o SG dos nós vem do EKS.
Transferir o SG do banco exige mudança coordenada nos dois repositórios e states, fora
deste PR. Essa parte da ADR não é declarada como integralmente implementada.
