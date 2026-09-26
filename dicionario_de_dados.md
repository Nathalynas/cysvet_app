# Dicionario de Dados

Schema apos a migration **V16** (MySQL 8). O Hibernate roda com `ddl-auto: validate`: o schema e definido
somente pelas migrations Flyway em `backend/src/main/resources/db/migration`.

**Colunas comuns** (`BaseEntity`, presentes em todas as tabelas):

| Coluna | Tipo | Descricao |
|---|---|---|
| `id` | BIGINT, PK, auto incremento | Identificador interno |
| `data_criacao` | DATETIME(6) | Preenchida no `@PrePersist` |
| `data_atualizacao` | DATETIME(6) | Atualizada no `@PreUpdate`; base do pull de sincronizacao |
| `versao` | BIGINT | Controle de concorrencia otimista (`@Version`) |

**Multiempresa:** tabelas com `tenant_id` (FK para `empresa`) pertencem a uma empresa. O Hibernate filtra as
consultas pela empresa ativa (`@TenantId`) e a busca por id passa por `TenantFilteredJpaRepository`.
Nos campos abaixo, "NN" indica `NOT NULL`.

## Empresa e acesso

### `empresa`

Clinica ou organizacao atendida. Criada no cadastro do primeiro administrador.

| Coluna | Tipo | Descricao |
|---|---|---|
| `empresa_id` | VARCHAR(36), NN, unico | UUID publico da empresa |
| `nome` | VARCHAR(255), NN | Nome da empresa |
| `email` | VARCHAR(255) | E-mail de contato |
| `ativo` | BOOLEAN, NN | Empresa ativa |

### `usuario`

Usuarios que acessam o sistema (global, sem `tenant_id`).

| Coluna | Tipo | Descricao |
|---|---|---|
| `nome` | VARCHAR(255), NN | Nome do veterinario ou administrador |
| `email` | VARCHAR(255), NN, unico | Login |
| `senha` | VARCHAR(255), NN | Hash BCrypt |
| `perfil` | VARCHAR(255), NN | `ADMIN` ou `VETERINARIO` |

### `usuario_empresa`

Vinculo entre usuario e empresa; o header `empresaid` so e aceito se existir vinculo ativo.

| Coluna | Tipo | Descricao |
|---|---|---|
| `id_usuario` | BIGINT, NN, FK `usuario` | Usuario |
| `id_empresa` | BIGINT, NN, FK `empresa` | Empresa |
| `ativo` | BOOLEAN, NN | Vinculo ativo |

Unico: `(id_usuario, id_empresa)`.

### `token_atualizacao`

Refresh tokens (rotativos: cada uso revoga o anterior).

| Coluna | Tipo | Descricao |
|---|---|---|
| `token` | VARCHAR(512), NN, unico | Refresh token emitido |
| `id_usuario` | BIGINT, NN, FK `usuario` | Dono do token |
| `expira_em` | DATETIME(6), NN | Vencimento |
| `revogado` | BOOLEAN, NN | Revogado por uso, logout ou invalidez |

## Rebanho

### `propriedade`

Fazenda atendida.

| Coluna | Tipo | Descricao |
|---|---|---|
| `tenant_id` | BIGINT, NN, FK `empresa` | Empresa dona |
| `id_externo` | VARCHAR(64), NN | Identificador estavel para sincronizacao offline |
| `nome` | VARCHAR(255), NN | Nome da fazenda |
| `nome_proprietario` | VARCHAR(255), NN | Produtor |
| `contato` | VARCHAR(255) | Telefone ou contato |
| `cidade`, `estado` | VARCHAR(255) | Localizacao |
| `observacoes` | VARCHAR(2000) | Observacoes |
| `status` | VARCHAR(32), NN, padrao `ATIVO` | `ATIVO` ou `INATIVO` (exclusao logica) |
| `id_usuario` | BIGINT, NN, FK `usuario` | Quem cadastrou |

Unico: `(tenant_id, id_externo)`.

### `lote`

Agrupamento de animais dentro da propriedade. Cada propriedade nasce com um lote padrao.

| Coluna | Tipo | Descricao |
|---|---|---|
| `tenant_id` | BIGINT, NN, FK `empresa` | Empresa dona |
| `id_externo` | VARCHAR(64), NN | Identificador para sincronizacao |
| `nome` | VARCHAR(255), NN | Nome do lote |
| `descricao` | VARCHAR(1000) | Descricao |
| `status` | VARCHAR(32), NN | `ATIVO` ou `INATIVO` |
| `id_propriedade` | BIGINT, NN, FK `propriedade` | Propriedade do lote |
| `id_usuario` | BIGINT, NN, FK `usuario` | Quem cadastrou |

Unico: `(tenant_id, id_externo)`.

### `animal`

Cadastro individual. Os campos de resumo reprodutivo sao **calculados** a partir da base (`base_*`) e dos eventos
em ordem cronologica (`ResumoReprodutivoAnimalService`).

| Coluna | Tipo | Descricao |
|---|---|---|
| `tenant_id` | BIGINT, NN, FK `empresa` | Empresa dona |
| `id_externo` | VARCHAR(64), NN | Identificador para sincronizacao |
| `codigo` | VARCHAR(255), NN | Brinco; unico por propriedade sem diferenciar maiusculas (validado no service) |
| `data_nascimento` | DATE | Nascimento |
| `id_propriedade` | BIGINT, NN, FK `propriedade` | Propriedade |
| `id_lote` | BIGINT, FK `lote` | Lote atual |
| `status` | VARCHAR(32), NN, padrao `ATIVO` | `ATIVO`, `VENDIDO`, `OBITO` ou `INATIVO` |
| `numero_lactacao` | INT, NN | Resumo: lactacoes |
| `data_ultimo_parto` | DATE | Resumo: ultimo parto |
| `data_inseminacao` | DATE | Resumo: ultima IA |
| `touro_ia` | VARCHAR(255) | Resumo: touro da ultima IA |
| `status_reprodutivo` | VARCHAR(32) | Resumo: situacao reprodutiva (nome do enum `StatusReprodutivoAnimal`, ex.: `PREGNANT`) |
| `historico_reprodutivo` | VARCHAR(2000) | Decisao/observacao livre |
| `base_numero_lactacao` | INT, NN | Base: lactacoes informadas no cadastro, importacao ou correcao |
| `base_data_ultimo_parto` | DATE | Base: ultimo parto informado |
| `base_data_inseminacao` | DATE | Base: ultima IA informada |
| `base_touro_ia` | VARCHAR(255) | Base: touro informado |
| `base_status_reprodutivo` | VARCHAR(32) | Base: situacao informada |
| `base_status_reprodutivo_em` | DATETIME(6) | Quando a situacao da base foi informada (eventos anteriores sao sobrepostos, posteriores prevalecem) |
| `id_usuario` | BIGINT, NN, FK `usuario` | Quem cadastrou |

Unico: `(tenant_id, id_externo)`.

### `animal_historico`

Linha do tempo do cadastro do animal (quem alterou o que).

| Coluna | Tipo | Descricao |
|---|---|---|
| `tenant_id` | BIGINT, NN, FK `empresa` | Empresa dona |
| `id_animal` | BIGINT, NN, FK `animal` | Animal |
| `id_usuario` | BIGINT, NN, FK `usuario` | Autor da alteracao |
| `tipo` | VARCHAR(32), NN | `CADASTRO`, `ATUALIZACAO`, `MOVIMENTACAO`, `STATUS` ou `STATUS_REPRODUTIVO` |
| `descricao` | VARCHAR(500), NN | Texto da alteracao |

## Visitas e eventos

### `visita`

Visita tecnica. A coleta de cada animal fica em JSON e tambem gera eventos reprodutivos (`VisitaEventosService`).

| Coluna | Tipo | Descricao |
|---|---|---|
| `tenant_id` | BIGINT, NN, FK `empresa` | Empresa dona |
| `id_externo` | VARCHAR(64), NN | Identificador para sincronizacao |
| `id_propriedade` | BIGINT, NN, FK `propriedade` | Propriedade visitada |
| `id_usuario` | BIGINT, NN, FK `usuario` | Veterinario |
| `data_visita` | DATE, NN | Data da visita |
| `observacoes` | VARCHAR(2000) | Observacoes gerais |
| `animais_json` | MEDIUMTEXT | Lista de `VisitaAnimalItemDto` (~1,3 KB por animal) |

Unico: `(tenant_id, id_externo)`.

### `evento_reprodutivo`

Fatos reprodutivos do animal. Registrados diretamente ou gerados pela visita.

| Coluna | Tipo | Descricao |
|---|---|---|
| `tenant_id` | BIGINT, NN, FK `empresa` | Empresa dona |
| `id_externo` | VARCHAR(64), NN | Identificador para sincronizacao; deterministico (visita + animal + tipo) quando gerado pela visita |
| `tipo` | VARCHAR(255), NN | `INSEMINATION`, `PREGNANCY_DIAGNOSIS`, `CALVING`, `DRY_OFF`, `GESTATIONAL_LOSS`, `POST_PARTUM_COMPLICATION`, `HEALTH_TREATMENT`, `MILK_CONTROL`, `LOT_MOVEMENT`, `DISCARD`, `DEATH`, `REPRODUCTIVE_STATUS_CHECK` |
| `data_evento` | DATE, NN | Data do fato |
| `data_prevista_parto` | DATE | Previsao de parto (IA + 282 dias) |
| `prenhez_confirmada` | BOOLEAN | Resultado do diagnostico |
| `observacoes` | VARCHAR(2000) | Observacoes |
| `detalhes_json` | TEXT | Detalhes por tipo (touro, crias, situacao observada...) |
| `id_animal` | BIGINT, NN, FK `animal` | Animal |
| `id_propriedade` | BIGINT, NN, FK `propriedade` | Propriedade (redundancia para filtros) |
| `id_visita` | BIGINT, FK `visita` | Visita que gerou o evento; nulo quando registrado diretamente |
| `id_usuario` | BIGINT, NN, FK `usuario` | Autor |

Unico: `(tenant_id, id_externo)`.

### `indicador_reprodutivo`

Snapshots de indicadores. Hoje a tabela nao tem consumidor no app (os indicadores sao calculados na hora).

| Coluna | Tipo | Descricao |
|---|---|---|
| `tenant_id` | BIGINT, NN, FK `empresa` | Empresa dona |
| `id_propriedade` | BIGINT, FK `propriedade` | Propriedade (nulo = todas) |
| `id_usuario` | BIGINT, NN, FK `usuario` | Quem gerou |
| `data_referencia` | DATE, NN | Data da consolidacao |
| `data_inicio`, `data_fim` | DATE | Janela do calculo |
| `total_propriedades`, `total_animais`, `total_eventos` | BIGINT, NN | Bases |
| `taxa_prenhez`, `taxa_servico`, `media_inseminacoes`, `intervalo_medio_partos` | DOUBLE, NN | Metricas |

## Sincronizacao

### `mutacao_cliente`

Idempotencia do `POST /api/sync`: cada mutacao aplicada fica registrada pela chave enviada pelo app.

| Coluna | Tipo | Descricao |
|---|---|---|
| `tenant_id` | BIGINT, NN, FK `empresa` | Empresa |
| `chave_mutacao` | VARCHAR(128), NN | Chave unica gerada no app |
| `nome_entidade` | VARCHAR(255), NN | `property`, `lot`, `animal`, `visit` ou `event` |
| `id_usuario` | BIGINT, NN | Usuario que enviou |
| `id_entidade` | BIGINT, NN | Id interno do registro afetado |

Unico: `(tenant_id, chave_mutacao)`.

### `registro_excluido`

Tombstones enviados no pull para o app apagar o registro local. Usado nas entidades com exclusao fisica
(visita e evento); as demais usam `status = INATIVO`.

| Coluna | Tipo | Descricao |
|---|---|---|
| `tenant_id` | BIGINT, NN, FK `empresa` | Empresa |
| `nome_entidade` | VARCHAR(64), NN | `visit` ou `event` |
| `id_externo` | VARCHAR(64), NN | Registro excluido |
| `id_usuario` | BIGINT, NN | Quem excluiu |
| `data_exclusao` | DATETIME(6), NN | Momento da exclusao |

Unico: `(tenant_id, nome_entidade, id_externo)`. O `data_atualizacao` e renovado quando o servidor recusa a edicao
offline de uma visita ja excluida, para o tombstone voltar no proximo pull.

## Indices do pull

`(tenant_id, data_atualizacao)` em `propriedade`, `lote`, `animal`, `visita`, `evento_reprodutivo` e
`registro_excluido` (V7 e V16).

## O que nao vira tabela

- `BaseEntity` e `TenantAwareEntity`: `@MappedSuperclass`, so contribuem com as colunas comuns e o `tenant_id`.
- Enums (`Perfil`, `StatusAnimal`, `StatusLote`, `StatusPropriedade`, `StatusReprodutivoAnimal`,
  `TipoEventoReprodutivo`, `TipoHistoricoAnimal`, `TipoOperacaoSincronizacao`): gravados como texto (nome do enum).
- DTOs, controllers, services e repositories.
