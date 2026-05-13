ALTER TABLE propriedade
    ADD COLUMN contato VARCHAR(255) NULL;

ALTER TABLE propriedade
    ADD COLUMN status VARCHAR(32) NOT NULL DEFAULT 'ATIVO';

ALTER TABLE animal
    ADD COLUMN sexo VARCHAR(64) NULL;

ALTER TABLE animal
    ADD COLUMN status VARCHAR(32) NOT NULL DEFAULT 'ATIVO';

CREATE INDEX idx_propriedade_tenant_status ON propriedade (tenant_id, status);
CREATE INDEX idx_animal_tenant_status ON animal (tenant_id, status);
