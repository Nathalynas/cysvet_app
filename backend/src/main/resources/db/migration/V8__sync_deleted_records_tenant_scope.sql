DELETE FROM registro_excluido
WHERE id IN (
    SELECT id
    FROM (
        SELECT re1.id
        FROM registro_excluido re1
        JOIN registro_excluido re2
          ON re1.tenant_id = re2.tenant_id
         AND re1.nome_entidade = re2.nome_entidade
         AND re1.id_externo = re2.id_externo
         AND (
            re1.data_atualizacao < re2.data_atualizacao
            OR (re1.data_atualizacao = re2.data_atualizacao AND re1.id < re2.id)
         )
    ) duplicated_rows
);

ALTER TABLE registro_excluido
    DROP INDEX uk_registro_excluido_tenant_usuario_entidade_id_externo;

ALTER TABLE registro_excluido
    ADD UNIQUE KEY uk_registro_excluido_tenant_entidade_id_externo (
        tenant_id,
        nome_entidade,
        id_externo
    );
