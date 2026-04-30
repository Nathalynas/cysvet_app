# Dicionario de Dados

## Tabelas de dominio

### `usuario`

Armazena os usuarios autenticados do sistema.

- `nome`: nome do veterinario ou operador
- `email`: login unico
- `senha`: senha criptografada
- `perfil`: perfil de acesso (`USER` ou `ADMIN`)
- `versao`: controle de concorrencia otimista

### `propriedade`

Representa a propriedade rural atendida.

- `id_externo`: identificador estavel para sincronizacao offline
- `nome_proprietario`: nome do proprietario
- `cidade`, `estado`: localizacao basica
- `id_usuario`: dono logico do registro

### `animal`

Cadastro individual de animais da propriedade.

- `codigo`: identificacao do animal
- `categoria`: categoria produtiva ou zootecnica
- `data_nascimento`: data de nascimento
- `numero_lactacao`: numero de lactacoes
- `data_ultimo_parto`: ultimo parto conhecido
- `historico_reprodutivo`: historico resumido
- `id_propriedade`: propriedade onde o animal pertence

### `visita`

Registra a visita tecnica realizada pelo veterinario.

- `data_visita`: data da visita
- `observacoes`: observacoes tecnicas
- `id_propriedade`: propriedade visitada
- `id_externo`: chave usada no sync offline-first

### `evento_reprodutivo`

Tabela central do negocio reprodutivo.

- `tipo`: tipo do evento reprodutivo
- `data_evento`: data de ocorrencia
- `data_prevista_parto`: previsao de parto quando aplicavel
- `prenhez_confirmada`: confirma ou nao prenhez
- `id_animal`: animal relacionado
- `id_propriedade`: redundancia controlada para consultas e filtros

### `indicador_reprodutivo`

Snapshots persistidos de indicadores reprodutivos.

- `data_referencia`: data da consolidacao
- `data_inicio`, `data_fim`: janela usada no calculo
- `total_propriedades`, `total_animais`, `total_eventos`: bases consolidadas
- `taxa_prenhez`, `taxa_servico`, `media_inseminacoes`, `intervalo_medio_partos`: metricas calculadas

## Tabelas de infraestrutura

### `token_atualizacao`

Suporta renovacao de sessao JWT.

- `token`: refresh token emitido
- `expira_em`: vencimento
- `revogado`: indica revogacao por logout ou invalidez

### `mutacao_cliente`

Registra mutacoes recebidas do app para idempotencia.

- `chave_mutacao`: chave unica enviada pelo cliente
- `nome_entidade`: entidade afetada
- `id_usuario`: usuario dono da operacao
- `id_entidade`: id interno associado apos processamento

### `registro_excluido`

Tombstones usados no `pull sync`.

- `nome_entidade`: tipo removido (`property`, `animal`, `visit`, `event`)
- `id_externo`: identificador sincronizavel do registro apagado
- `data_exclusao`: momento logico da exclusao
- `data_atualizacao`: usado para consultar exclusoes posteriores a um marco de sync

## Classes do backend que nao viram tabela

### `BaseEntity`

Nao vira tabela porque usa `@MappedSuperclass`. Ela so injeta campos comuns nas outras entidades:

- `id`
- `createdAt`
- `updatedAt`
- `version`

### `Perfil`, `TipoEventoReprodutivo`, `TipoOperacaoSincronizacao`

Nao viram tabela porque sao `enum`. Seus valores sao armazenados em colunas `VARCHAR`.

### DTOs, controllers, services e repositories

Nao fazem parte do mapeamento JPA. Eles organizam API, regras de negocio e acesso a dados, mas nao representam tabelas.
