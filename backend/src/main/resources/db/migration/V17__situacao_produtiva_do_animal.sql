-- Situacao produtiva (lactante, seca, novilha, pre parto) separada da
-- reprodutiva. Antes a secagem gravava "seca" na situacao reprodutiva e a vaca
-- deixava de aparecer como prenha; na planilha de campo "seca" e produtiva.
-- Como no resumo reprodutivo (V14), ha o valor calculado e a base informada.
ALTER TABLE animal ADD COLUMN situacao_produtiva VARCHAR(32) NULL;
ALTER TABLE animal ADD COLUMN base_situacao_produtiva VARCHAR(32) NULL;
ALTER TABLE animal ADD COLUMN base_situacao_produtiva_em DATETIME(6) NULL;

-- "Seca" informada como situacao reprodutiva passa a ser a base produtiva.
-- A situacao reprodutiva real nao e conhecida: fica sem base.
UPDATE animal
SET base_situacao_produtiva = 'SECA',
    base_situacao_produtiva_em = base_status_reprodutivo_em,
    base_status_reprodutivo = NULL,
    base_status_reprodutivo_em = NULL
WHERE base_status_reprodutivo = 'DRY';

-- O resumo e recalculado na proxima alteracao do animal (visita, evento ou
-- edicao); ate la a situacao reprodutiva fica sem valor em vez de "seca".
UPDATE animal
SET situacao_produtiva = 'SECA',
    status_reprodutivo = NULL
WHERE status_reprodutivo = 'DRY';
