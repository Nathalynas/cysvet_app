CREATE TABLE animal_historico (
    id BIGINT NOT NULL AUTO_INCREMENT,
    data_criacao DATETIME(6) NOT NULL,
    data_atualizacao DATETIME(6) NOT NULL,
    versao BIGINT NOT NULL,
    tenant_id BIGINT NOT NULL,
    id_animal BIGINT NOT NULL,
    id_usuario BIGINT NOT NULL,
    tipo VARCHAR(32) NOT NULL,
    descricao VARCHAR(500) NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT fk_animal_historico_empresa FOREIGN KEY (tenant_id) REFERENCES empresa (id),
    CONSTRAINT fk_animal_historico_animal FOREIGN KEY (id_animal) REFERENCES animal (id),
    CONSTRAINT fk_animal_historico_usuario FOREIGN KEY (id_usuario) REFERENCES usuario (id)
);

CREATE INDEX idx_animal_historico_animal_data ON animal_historico (id_animal, data_criacao);
CREATE INDEX idx_animal_historico_tenant_id ON animal_historico (tenant_id);

INSERT INTO animal_historico (
    data_criacao,
    data_atualizacao,
    versao,
    tenant_id,
    id_animal,
    id_usuario,
    tipo,
    descricao
)
SELECT
    a.data_criacao,
    a.data_atualizacao,
    0,
    a.tenant_id,
    a.id,
    a.id_usuario,
    'CADASTRO',
    'Cadastro anterior ao inicio da auditoria.'
FROM animal a;
