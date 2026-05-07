CREATE TABLE empresa (
    id BIGINT NOT NULL AUTO_INCREMENT,
    data_criacao DATETIME(6) NOT NULL,
    data_atualizacao DATETIME(6) NOT NULL,
    versao BIGINT NOT NULL,
    empresa_id VARCHAR(36) NOT NULL,
    nome VARCHAR(255) NOT NULL,
    email VARCHAR(255) NULL,
    ativo BOOLEAN NOT NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uk_empresa_empresa_id (empresa_id)
);

CREATE TABLE usuario_empresa (
    id BIGINT NOT NULL AUTO_INCREMENT,
    data_criacao DATETIME(6) NOT NULL,
    data_atualizacao DATETIME(6) NOT NULL,
    versao BIGINT NOT NULL,
    id_usuario BIGINT NOT NULL,
    id_empresa BIGINT NOT NULL,
    ativo BOOLEAN NOT NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uk_usuario_empresa_usuario_empresa (id_usuario, id_empresa),
    CONSTRAINT fk_usuario_empresa_usuario FOREIGN KEY (id_usuario) REFERENCES usuario (id),
    CONSTRAINT fk_usuario_empresa_empresa FOREIGN KEY (id_empresa) REFERENCES empresa (id)
);

INSERT INTO empresa (data_criacao, data_atualizacao, versao, empresa_id, nome, email, ativo)
SELECT
    CURRENT_TIMESTAMP(6),
    CURRENT_TIMESTAMP(6),
    0,
    CONCAT('legacy-user-', id),
    CONCAT('Empresa de ', nome),
    email,
    TRUE
FROM usuario;

INSERT INTO usuario_empresa (data_criacao, data_atualizacao, versao, id_usuario, id_empresa, ativo)
SELECT
    CURRENT_TIMESTAMP(6),
    CURRENT_TIMESTAMP(6),
    0,
    u.id,
    e.id,
    TRUE
FROM usuario u
JOIN empresa e ON e.empresa_id = CONCAT('legacy-user-', u.id);

UPDATE usuario
SET perfil = 'VETERINARIAN'
WHERE perfil = 'USER';

ALTER TABLE propriedade ADD COLUMN tenant_id BIGINT NULL;
ALTER TABLE animal ADD COLUMN tenant_id BIGINT NULL;
ALTER TABLE visita ADD COLUMN tenant_id BIGINT NULL;
ALTER TABLE evento_reprodutivo ADD COLUMN tenant_id BIGINT NULL;
ALTER TABLE indicador_reprodutivo ADD COLUMN tenant_id BIGINT NULL;
ALTER TABLE mutacao_cliente ADD COLUMN tenant_id BIGINT NULL;
ALTER TABLE registro_excluido ADD COLUMN tenant_id BIGINT NULL;

UPDATE propriedade p
SET tenant_id = (
    SELECT ue.id_empresa
    FROM usuario_empresa ue
    WHERE ue.id_usuario = p.id_usuario
    LIMIT 1
)
WHERE tenant_id IS NULL;

UPDATE animal a
SET tenant_id = (
    SELECT ue.id_empresa
    FROM usuario_empresa ue
    WHERE ue.id_usuario = a.id_usuario
    LIMIT 1
)
WHERE tenant_id IS NULL;

UPDATE visita v
SET tenant_id = (
    SELECT ue.id_empresa
    FROM usuario_empresa ue
    WHERE ue.id_usuario = v.id_usuario
    LIMIT 1
)
WHERE tenant_id IS NULL;

UPDATE evento_reprodutivo er
SET tenant_id = (
    SELECT ue.id_empresa
    FROM usuario_empresa ue
    WHERE ue.id_usuario = er.id_usuario
    LIMIT 1
)
WHERE tenant_id IS NULL;

UPDATE indicador_reprodutivo ir
SET tenant_id = (
    SELECT ue.id_empresa
    FROM usuario_empresa ue
    WHERE ue.id_usuario = ir.id_usuario
    LIMIT 1
)
WHERE tenant_id IS NULL;

UPDATE mutacao_cliente mc
SET tenant_id = (
    SELECT ue.id_empresa
    FROM usuario_empresa ue
    WHERE ue.id_usuario = mc.id_usuario
    LIMIT 1
)
WHERE tenant_id IS NULL;

UPDATE registro_excluido re
SET tenant_id = (
    SELECT ue.id_empresa
    FROM usuario_empresa ue
    WHERE ue.id_usuario = re.id_usuario
    LIMIT 1
)
WHERE tenant_id IS NULL;

ALTER TABLE propriedade MODIFY COLUMN tenant_id BIGINT NOT NULL;
ALTER TABLE animal MODIFY COLUMN tenant_id BIGINT NOT NULL;
ALTER TABLE visita MODIFY COLUMN tenant_id BIGINT NOT NULL;
ALTER TABLE evento_reprodutivo MODIFY COLUMN tenant_id BIGINT NOT NULL;
ALTER TABLE indicador_reprodutivo MODIFY COLUMN tenant_id BIGINT NOT NULL;
ALTER TABLE mutacao_cliente MODIFY COLUMN tenant_id BIGINT NOT NULL;
ALTER TABLE registro_excluido MODIFY COLUMN tenant_id BIGINT NOT NULL;

ALTER TABLE propriedade ADD CONSTRAINT fk_propriedade_empresa FOREIGN KEY (tenant_id) REFERENCES empresa (id);
ALTER TABLE animal ADD CONSTRAINT fk_animal_empresa FOREIGN KEY (tenant_id) REFERENCES empresa (id);
ALTER TABLE visita ADD CONSTRAINT fk_visita_empresa FOREIGN KEY (tenant_id) REFERENCES empresa (id);
ALTER TABLE evento_reprodutivo ADD CONSTRAINT fk_evento_reprodutivo_empresa FOREIGN KEY (tenant_id) REFERENCES empresa (id);
ALTER TABLE indicador_reprodutivo ADD CONSTRAINT fk_indicador_reprodutivo_empresa FOREIGN KEY (tenant_id) REFERENCES empresa (id);
ALTER TABLE mutacao_cliente ADD CONSTRAINT fk_mutacao_cliente_empresa FOREIGN KEY (tenant_id) REFERENCES empresa (id);
ALTER TABLE registro_excluido ADD CONSTRAINT fk_registro_excluido_empresa FOREIGN KEY (tenant_id) REFERENCES empresa (id);

ALTER TABLE propriedade DROP INDEX uk_propriedade_id_externo;
ALTER TABLE propriedade ADD UNIQUE KEY uk_propriedade_tenant_id_externo (tenant_id, id_externo);
ALTER TABLE animal DROP INDEX uk_animal_id_externo;
ALTER TABLE animal ADD UNIQUE KEY uk_animal_tenant_id_externo (tenant_id, id_externo);
ALTER TABLE visita DROP INDEX uk_visita_id_externo;
ALTER TABLE visita ADD UNIQUE KEY uk_visita_tenant_id_externo (tenant_id, id_externo);
ALTER TABLE evento_reprodutivo DROP INDEX uk_evento_reprodutivo_id_externo;
ALTER TABLE evento_reprodutivo ADD UNIQUE KEY uk_evento_reprodutivo_tenant_id_externo (tenant_id, id_externo);
ALTER TABLE mutacao_cliente DROP INDEX uk_mutacao_cliente_chave_mutacao;
ALTER TABLE mutacao_cliente ADD UNIQUE KEY uk_mutacao_cliente_tenant_chave (tenant_id, chave_mutacao);
ALTER TABLE registro_excluido DROP INDEX uk_registro_excluido_usuario_entidade_id_externo;
ALTER TABLE registro_excluido ADD UNIQUE KEY uk_registro_excluido_tenant_usuario_entidade_id_externo (
    tenant_id,
    id_usuario,
    nome_entidade,
    id_externo
);

CREATE INDEX idx_propriedade_tenant_id ON propriedade (tenant_id);
CREATE INDEX idx_animal_tenant_id ON animal (tenant_id);
CREATE INDEX idx_visita_tenant_id ON visita (tenant_id);
CREATE INDEX idx_evento_reprodutivo_tenant_id ON evento_reprodutivo (tenant_id);
CREATE INDEX idx_indicador_reprodutivo_tenant_id ON indicador_reprodutivo (tenant_id);
CREATE INDEX idx_mutacao_cliente_tenant_id ON mutacao_cliente (tenant_id);
CREATE INDEX idx_registro_excluido_tenant_id ON registro_excluido (tenant_id);
