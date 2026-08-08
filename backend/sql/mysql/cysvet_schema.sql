CREATE DATABASE IF NOT EXISTS cysvet
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE cysvet;

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

DROP TABLE IF EXISTS indicador_reprodutivo;
DROP TABLE IF EXISTS registro_excluido;
DROP TABLE IF EXISTS mutacao_cliente;
DROP TABLE IF EXISTS token_atualizacao;
DROP TABLE IF EXISTS evento_reprodutivo;
DROP TABLE IF EXISTS visita;
DROP TABLE IF EXISTS animal;
DROP TABLE IF EXISTS lote;
DROP TABLE IF EXISTS propriedade;
DROP TABLE IF EXISTS usuario_empresa;
DROP TABLE IF EXISTS empresa;
DROP TABLE IF EXISTS usuario;

SET FOREIGN_KEY_CHECKS = 1;

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE usuario (
    id BIGINT NOT NULL AUTO_INCREMENT,
    data_criacao DATETIME(6) NOT NULL,
    data_atualizacao DATETIME(6) NOT NULL,
    versao BIGINT NOT NULL,
    nome VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL,
    senha VARCHAR(255) NOT NULL,
    perfil VARCHAR(255) NOT NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uk_usuario_email (email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

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
    CONSTRAINT fk_usuario_empresa_usuario
        FOREIGN KEY (id_usuario) REFERENCES usuario (id),
    CONSTRAINT fk_usuario_empresa_empresa
        FOREIGN KEY (id_empresa) REFERENCES empresa (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE propriedade (
    id BIGINT NOT NULL AUTO_INCREMENT,
    data_criacao DATETIME(6) NOT NULL,
    data_atualizacao DATETIME(6) NOT NULL,
    versao BIGINT NOT NULL,
    tenant_id BIGINT NOT NULL,
    id_externo VARCHAR(64) NOT NULL,
    nome VARCHAR(255) NOT NULL,
    nome_proprietario VARCHAR(255) NOT NULL,
    contato VARCHAR(255) NULL,
    cidade VARCHAR(255) NULL,
    estado VARCHAR(255) NULL,
    observacoes VARCHAR(2000) NULL,
    status VARCHAR(32) NOT NULL DEFAULT 'ATIVO',
    id_usuario BIGINT NOT NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uk_propriedade_tenant_id_externo (tenant_id, id_externo),
    KEY idx_propriedade_tenant_id (tenant_id),
    KEY idx_propriedade_tenant_status (tenant_id, status),
    CONSTRAINT fk_propriedade_empresa
        FOREIGN KEY (tenant_id) REFERENCES empresa (id),
    CONSTRAINT fk_propriedade_usuario
        FOREIGN KEY (id_usuario) REFERENCES usuario (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

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
    UNIQUE KEY uk_lote_tenant_id_externo (tenant_id, id_externo),
    KEY idx_lote_tenant_id (tenant_id),
    KEY idx_lote_id_propriedade (id_propriedade),
    KEY idx_lote_id_usuario (id_usuario),
    KEY idx_lote_status (status),
    KEY idx_lote_tenant_data_atualizacao (tenant_id, data_atualizacao),
    CONSTRAINT fk_lote_empresa
        FOREIGN KEY (tenant_id) REFERENCES empresa (id),
    CONSTRAINT fk_lote_propriedade
        FOREIGN KEY (id_propriedade) REFERENCES propriedade (id),
    CONSTRAINT fk_lote_usuario
        FOREIGN KEY (id_usuario) REFERENCES usuario (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE animal (
    id BIGINT NOT NULL AUTO_INCREMENT,
    data_criacao DATETIME(6) NOT NULL,
    data_atualizacao DATETIME(6) NOT NULL,
    versao BIGINT NOT NULL,
    tenant_id BIGINT NOT NULL,
    id_externo VARCHAR(64) NOT NULL,
    codigo VARCHAR(255) NOT NULL,
    categoria VARCHAR(255) NOT NULL,
    sexo VARCHAR(64) NULL,
    status VARCHAR(32) NOT NULL DEFAULT 'ATIVO',
    data_nascimento DATE NULL,
    numero_lactacao INT NOT NULL,
    data_ultimo_parto DATE NULL,
    data_inseminacao DATE NULL,
    historico_reprodutivo VARCHAR(2000) NULL,
    status_reprodutivo VARCHAR(32) NULL,
    id_propriedade BIGINT NOT NULL,
    id_lote BIGINT NULL,
    id_usuario BIGINT NOT NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uk_animal_tenant_id_externo (tenant_id, id_externo),
    KEY idx_animal_tenant_id (tenant_id),
    KEY idx_animal_tenant_status (tenant_id, status),
    KEY idx_animal_tenant_status_reprodutivo (tenant_id, status_reprodutivo),
    KEY idx_animal_id_lote (id_lote),
    CONSTRAINT fk_animal_empresa
        FOREIGN KEY (tenant_id) REFERENCES empresa (id),
    CONSTRAINT fk_animal_propriedade
        FOREIGN KEY (id_propriedade) REFERENCES propriedade (id),
    CONSTRAINT fk_animal_lote
        FOREIGN KEY (id_lote) REFERENCES lote (id),
    CONSTRAINT fk_animal_usuario
        FOREIGN KEY (id_usuario) REFERENCES usuario (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE visita (
    id BIGINT NOT NULL AUTO_INCREMENT,
    data_criacao DATETIME(6) NOT NULL,
    data_atualizacao DATETIME(6) NOT NULL,
    versao BIGINT NOT NULL,
    tenant_id BIGINT NOT NULL,
    id_externo VARCHAR(64) NOT NULL,
    id_propriedade BIGINT NOT NULL,
    id_usuario BIGINT NOT NULL,
    data_visita DATE NOT NULL,
    observacoes VARCHAR(2000) NULL,
    animais_json TEXT NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uk_visita_tenant_id_externo (tenant_id, id_externo),
    KEY idx_visita_tenant_id (tenant_id),
    CONSTRAINT fk_visita_empresa
        FOREIGN KEY (tenant_id) REFERENCES empresa (id),
    CONSTRAINT fk_visita_propriedade
        FOREIGN KEY (id_propriedade) REFERENCES propriedade (id),
    CONSTRAINT fk_visita_usuario
        FOREIGN KEY (id_usuario) REFERENCES usuario (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE evento_reprodutivo (
    id BIGINT NOT NULL AUTO_INCREMENT,
    data_criacao DATETIME(6) NOT NULL,
    data_atualizacao DATETIME(6) NOT NULL,
    versao BIGINT NOT NULL,
    tenant_id BIGINT NOT NULL,
    id_externo VARCHAR(64) NOT NULL,
    tipo VARCHAR(255) NOT NULL,
    data_evento DATE NOT NULL,
    data_prevista_parto DATE NULL,
    prenhez_confirmada BOOLEAN NULL,
    observacoes VARCHAR(2000) NULL,
    id_animal BIGINT NOT NULL,
    id_propriedade BIGINT NOT NULL,
    id_usuario BIGINT NOT NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uk_evento_reprodutivo_tenant_id_externo (tenant_id, id_externo),
    KEY idx_evento_reprodutivo_tenant_id (tenant_id),
    CONSTRAINT fk_evento_reprodutivo_empresa
        FOREIGN KEY (tenant_id) REFERENCES empresa (id),
    CONSTRAINT fk_evento_reprodutivo_animal
        FOREIGN KEY (id_animal) REFERENCES animal (id),
    CONSTRAINT fk_evento_reprodutivo_propriedade
        FOREIGN KEY (id_propriedade) REFERENCES propriedade (id),
    CONSTRAINT fk_evento_reprodutivo_usuario
        FOREIGN KEY (id_usuario) REFERENCES usuario (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE token_atualizacao (
    id BIGINT NOT NULL AUTO_INCREMENT,
    data_criacao DATETIME(6) NOT NULL,
    data_atualizacao DATETIME(6) NOT NULL,
    versao BIGINT NOT NULL,
    token VARCHAR(512) NOT NULL,
    id_usuario BIGINT NOT NULL,
    expira_em DATETIME(6) NOT NULL,
    revogado BOOLEAN NOT NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uk_token_atualizacao_token (token),
    CONSTRAINT fk_token_atualizacao_usuario
        FOREIGN KEY (id_usuario) REFERENCES usuario (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE mutacao_cliente (
    id BIGINT NOT NULL AUTO_INCREMENT,
    data_criacao DATETIME(6) NOT NULL,
    data_atualizacao DATETIME(6) NOT NULL,
    versao BIGINT NOT NULL,
    tenant_id BIGINT NOT NULL,
    chave_mutacao VARCHAR(128) NOT NULL,
    nome_entidade VARCHAR(255) NOT NULL,
    id_usuario BIGINT NOT NULL,
    id_entidade BIGINT NOT NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uk_mutacao_cliente_tenant_chave (tenant_id, chave_mutacao),
    KEY idx_mutacao_cliente_tenant_id (tenant_id),
    CONSTRAINT fk_mutacao_cliente_empresa
        FOREIGN KEY (tenant_id) REFERENCES empresa (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE registro_excluido (
    id BIGINT NOT NULL AUTO_INCREMENT,
    data_criacao DATETIME(6) NOT NULL,
    data_atualizacao DATETIME(6) NOT NULL,
    versao BIGINT NOT NULL,
    tenant_id BIGINT NOT NULL,
    nome_entidade VARCHAR(64) NOT NULL,
    id_externo VARCHAR(64) NOT NULL,
    id_usuario BIGINT NOT NULL,
    data_exclusao DATETIME(6) NOT NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uk_registro_excluido_tenant_entidade_id_externo (tenant_id, nome_entidade, id_externo),
    KEY idx_registro_excluido_tenant_id (tenant_id),
    CONSTRAINT fk_registro_excluido_empresa
        FOREIGN KEY (tenant_id) REFERENCES empresa (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE indicador_reprodutivo (
    id BIGINT NOT NULL AUTO_INCREMENT,
    data_criacao DATETIME(6) NOT NULL,
    data_atualizacao DATETIME(6) NOT NULL,
    versao BIGINT NOT NULL,
    tenant_id BIGINT NOT NULL,
    id_usuario BIGINT NOT NULL,
    id_propriedade BIGINT NULL,
    data_referencia DATE NOT NULL,
    data_inicio DATE NULL,
    data_fim DATE NULL,
    total_propriedades BIGINT NOT NULL,
    total_animais BIGINT NOT NULL,
    total_eventos BIGINT NOT NULL,
    taxa_prenhez DOUBLE NOT NULL,
    taxa_servico DOUBLE NOT NULL,
    media_inseminacoes DOUBLE NOT NULL,
    intervalo_medio_partos DOUBLE NOT NULL,
    PRIMARY KEY (id),
    KEY idx_indicador_reprodutivo_tenant_id (tenant_id),
    CONSTRAINT fk_indicador_reprodutivo_empresa
        FOREIGN KEY (tenant_id) REFERENCES empresa (id),
    CONSTRAINT fk_indicador_reprodutivo_usuario
        FOREIGN KEY (id_usuario) REFERENCES usuario (id),
    CONSTRAINT fk_indicador_reprodutivo_propriedade
        FOREIGN KEY (id_propriedade) REFERENCES propriedade (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
