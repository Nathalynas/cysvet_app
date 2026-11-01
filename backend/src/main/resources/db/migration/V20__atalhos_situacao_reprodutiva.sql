-- Atalhos de situacao reprodutiva que o veterinario escolhe para a visita
-- (valores separados por virgula). Nulo usa os atalhos padrao do app.
ALTER TABLE usuario ADD COLUMN atalhos_situacao_reprodutiva VARCHAR(512) NULL;
