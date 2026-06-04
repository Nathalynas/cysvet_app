CREATE TABLE lote (
    id BIGINT NOT NULL AUTO_INCREMENT,
    data_criacao DATETIME(6) NOT NULL,
    data_atualizacao DATETIME(6) NOT NULL,
    versao BIGINT NOT NULL,
    tenant_id BIGINT NOT NULL,
    id_externo VARCHAR(64) NOT NULL,
    nome VARCHAR(255) NOT NULL,
    descricao VARCHAR(1000) NULL,
    status VARCHAR(32) NOT NULL,
    id_propriedade BIGINT NOT NULL,
    id_usuario BIGINT NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT fk_lote_empresa FOREIGN KEY (tenant_id) REFERENCES empresa (id),
    CONSTRAINT fk_lote_propriedade FOREIGN KEY (id_propriedade) REFERENCES propriedade (id),
    CONSTRAINT fk_lote_usuario FOREIGN KEY (id_usuario) REFERENCES usuario (id),
    CONSTRAINT uk_lote_tenant_id_externo UNIQUE (tenant_id, id_externo)
);

CREATE INDEX idx_lote_tenant_id ON lote (tenant_id);
CREATE INDEX idx_lote_id_propriedade ON lote (id_propriedade);
CREATE INDEX idx_lote_id_usuario ON lote (id_usuario);
CREATE INDEX idx_lote_status ON lote (status);
CREATE INDEX idx_lote_tenant_data_atualizacao ON lote (tenant_id, data_atualizacao);

ALTER TABLE animal
    ADD COLUMN id_lote BIGINT NULL;

ALTER TABLE animal
    ADD CONSTRAINT fk_animal_lote FOREIGN KEY (id_lote) REFERENCES lote (id);

CREATE INDEX idx_animal_id_lote ON animal (id_lote);
