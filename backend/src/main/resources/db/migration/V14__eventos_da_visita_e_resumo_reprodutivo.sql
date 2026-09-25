-- Eventos gerados por uma visita guardam a visita de origem, para serem
-- refeitos quando a visita for editada e removidos quando ela for excluida.
ALTER TABLE evento_reprodutivo
    ADD COLUMN id_visita BIGINT NULL;

ALTER TABLE evento_reprodutivo
    ADD CONSTRAINT fk_evento_reprodutivo_visita FOREIGN KEY (id_visita) REFERENCES visita (id);

CREATE INDEX idx_evento_reprodutivo_id_visita ON evento_reprodutivo (id_visita);
CREATE INDEX idx_evento_reprodutivo_animal_data ON evento_reprodutivo (id_animal, data_evento);

-- Ponto de partida do resumo reprodutivo: valores informados no cadastro,
-- na importacao ou em correcao manual. O resumo exibido no animal passa a
-- ser recalculado a partir desta base e dos eventos.
ALTER TABLE animal ADD COLUMN base_numero_lactacao INT NULL;
ALTER TABLE animal ADD COLUMN base_data_ultimo_parto DATE NULL;
ALTER TABLE animal ADD COLUMN base_data_inseminacao DATE NULL;
ALTER TABLE animal ADD COLUMN base_touro_ia VARCHAR(255) NULL;
ALTER TABLE animal ADD COLUMN base_status_reprodutivo VARCHAR(32) NULL;
ALTER TABLE animal ADD COLUMN base_status_reprodutivo_em DATETIME(6) NULL;

-- Os valores atuais ja refletem os eventos existentes; usa-los como base
-- mantem os animais inalterados apos a migracao.
UPDATE animal
SET base_numero_lactacao = numero_lactacao,
    base_data_ultimo_parto = data_ultimo_parto,
    base_data_inseminacao = data_inseminacao,
    base_touro_ia = touro_ia,
    base_status_reprodutivo = status_reprodutivo,
    base_status_reprodutivo_em = CURRENT_TIMESTAMP(6);

ALTER TABLE animal MODIFY COLUMN base_numero_lactacao INT NOT NULL;
