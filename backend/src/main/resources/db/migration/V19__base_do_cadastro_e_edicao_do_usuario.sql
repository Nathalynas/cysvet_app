-- Conflito do sync compara com a ultima edicao feita por uma pessoa. A
-- data_atualizacao tambem muda quando o servidor recalcula o resumo depois de
-- uma visita, e isso descartava edicoes feitas sem sinal antes da visita subir.
ALTER TABLE animal ADD COLUMN data_edicao_usuario DATETIME(6) NULL;
UPDATE animal SET data_edicao_usuario = data_atualizacao;

-- Animais cujo resumo precisa ser recalculado na inicializacao do servidor.
ALTER TABLE animal ADD COLUMN resumo_pendente BOOLEAN NOT NULL DEFAULT FALSE;

-- A situacao informada no cadastro ou na importacao e o ponto de partida, sem
-- instante: eventos anteriores ao cadastro (visita lancada depois) passam por
-- cima dela. So a correcao feita depois, na tela do animal, guarda o instante.
-- A base gravada junto com o cadastro (ate 5 s depois) e a do cadastro.
UPDATE animal
SET base_status_reprodutivo_em = NULL,
    resumo_pendente = TRUE
WHERE base_status_reprodutivo_em IS NOT NULL
  AND TIMESTAMPDIFF(SECOND, data_criacao, base_status_reprodutivo_em) BETWEEN -5 AND 5;

UPDATE animal
SET base_situacao_produtiva_em = NULL,
    resumo_pendente = TRUE
WHERE base_situacao_produtiva_em IS NOT NULL
  AND TIMESTAMPDIFF(SECOND, data_criacao, base_situacao_produtiva_em) BETWEEN -5 AND 5;
