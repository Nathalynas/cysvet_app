ALTER TABLE animal
    ADD COLUMN status_reprodutivo VARCHAR(32) NULL;

CREATE INDEX idx_animal_tenant_status_reprodutivo ON animal (tenant_id, status_reprodutivo);
