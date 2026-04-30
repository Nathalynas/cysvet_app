
CREATE DATABASE IF NOT EXISTS reprocampo
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE reprocampo;

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

DROP TABLE IF EXISTS indicador_reprodutivo;
DROP TABLE IF EXISTS registro_excluido;
DROP TABLE IF EXISTS mutacao_cliente;
DROP TABLE IF EXISTS token_atualizacao;
DROP TABLE IF EXISTS evento_reprodutivo;
DROP TABLE IF EXISTS visita;
DROP TABLE IF EXISTS animal;
DROP TABLE IF EXISTS propriedade;
DROP TABLE IF EXISTS usuario;

SET FOREIGN_KEY_CHECKS = 1;

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

CREATE TABLE propriedade (
    id BIGINT NOT NULL AUTO_INCREMENT,
    data_criacao DATETIME(6) NOT NULL,
    data_atualizacao DATETIME(6) NOT NULL,
    versao BIGINT NOT NULL,
    id_externo VARCHAR(64) NOT NULL,
    nome VARCHAR(255) NOT NULL,
    nome_proprietario VARCHAR(255) NOT NULL,
    cidade VARCHAR(255) NULL,
    estado VARCHAR(255) NULL,
    observacoes VARCHAR(2000) NULL,
    id_usuario BIGINT NOT NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uk_propriedade_id_externo (id_externo),
    KEY idx_propriedade_id_usuario (id_usuario),
    KEY idx_propriedade_id_usuario_data_atualizacao (id_usuario, data_atualizacao),
    CONSTRAINT fk_propriedade_usuario
        FOREIGN KEY (id_usuario) REFERENCES usuario (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE animal (
    id BIGINT NOT NULL AUTO_INCREMENT,
    data_criacao DATETIME(6) NOT NULL,
    data_atualizacao DATETIME(6) NOT NULL,
    versao BIGINT NOT NULL,
    id_externo VARCHAR(64) NOT NULL,
    codigo VARCHAR(255) NOT NULL,
    categoria VARCHAR(255) NOT NULL,
    data_nascimento DATE NULL,
    numero_lactacao INT NOT NULL,
    data_ultimo_parto DATE NULL,
    historico_reprodutivo VARCHAR(2000) NULL,
    id_propriedade BIGINT NOT NULL,
    id_usuario BIGINT NOT NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uk_animal_id_externo (id_externo),
    KEY idx_animal_id_propriedade (id_propriedade),
    KEY idx_animal_id_usuario (id_usuario),
    KEY idx_animal_id_usuario_data_atualizacao (id_usuario, data_atualizacao),
    CONSTRAINT fk_animal_propriedade
        FOREIGN KEY (id_propriedade) REFERENCES propriedade (id),
    CONSTRAINT fk_animal_usuario
        FOREIGN KEY (id_usuario) REFERENCES usuario (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE visita (
    id BIGINT NOT NULL AUTO_INCREMENT,
    data_criacao DATETIME(6) NOT NULL,
    data_atualizacao DATETIME(6) NOT NULL,
    versao BIGINT NOT NULL,
    id_externo VARCHAR(64) NOT NULL,
    id_propriedade BIGINT NOT NULL,
    id_usuario BIGINT NOT NULL,
    data_visita DATE NOT NULL,
    observacoes VARCHAR(2000) NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uk_visita_id_externo (id_externo),
    KEY idx_visita_id_propriedade (id_propriedade),
    KEY idx_visita_id_usuario (id_usuario),
    KEY idx_visita_id_usuario_data_atualizacao (id_usuario, data_atualizacao),
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
    UNIQUE KEY uk_evento_reprodutivo_id_externo (id_externo),
    KEY idx_evento_reprodutivo_id_animal (id_animal),
    KEY idx_evento_reprodutivo_id_propriedade (id_propriedade),
    KEY idx_evento_reprodutivo_id_usuario (id_usuario),
    KEY idx_evento_reprodutivo_id_usuario_data_atualizacao (id_usuario, data_atualizacao),
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
    KEY idx_token_atualizacao_id_usuario (id_usuario),
    CONSTRAINT fk_token_atualizacao_usuario
        FOREIGN KEY (id_usuario) REFERENCES usuario (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE mutacao_cliente (
    id BIGINT NOT NULL AUTO_INCREMENT,
    data_criacao DATETIME(6) NOT NULL,
    data_atualizacao DATETIME(6) NOT NULL,
    versao BIGINT NOT NULL,
    chave_mutacao VARCHAR(128) NOT NULL,
    nome_entidade VARCHAR(255) NOT NULL,
    id_usuario BIGINT NOT NULL,
    id_entidade BIGINT NOT NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uk_mutacao_cliente_chave_mutacao (chave_mutacao)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE registro_excluido (
    id BIGINT NOT NULL AUTO_INCREMENT,
    data_criacao DATETIME(6) NOT NULL,
    data_atualizacao DATETIME(6) NOT NULL,
    versao BIGINT NOT NULL,
    nome_entidade VARCHAR(64) NOT NULL,
    id_externo VARCHAR(64) NOT NULL,
    id_usuario BIGINT NOT NULL,
    data_exclusao DATETIME(6) NOT NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uk_registro_excluido_usuario_entidade_id_externo (id_usuario, nome_entidade, id_externo),
    KEY idx_registro_excluido_usuario_entidade_data_atualizacao (id_usuario, nome_entidade, data_atualizacao)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE indicador_reprodutivo (
    id BIGINT NOT NULL AUTO_INCREMENT,
    data_criacao DATETIME(6) NOT NULL,
    data_atualizacao DATETIME(6) NOT NULL,
    versao BIGINT NOT NULL,
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
    KEY idx_indicador_reprodutivo_id_usuario (id_usuario),
    KEY idx_indicador_reprodutivo_id_propriedade (id_propriedade),
    CONSTRAINT fk_indicador_reprodutivo_usuario
        FOREIGN KEY (id_usuario) REFERENCES usuario (id),
    CONSTRAINT fk_indicador_reprodutivo_propriedade
        FOREIGN KEY (id_propriedade) REFERENCES propriedade (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
