-- O pull de sincronizacao busca, por empresa, o que mudou depois do checkpoint
-- (tenant_id = ? AND data_atualizacao > ?). So o lote tinha indice para isso (V7).
CREATE INDEX idx_propriedade_tenant_data_atualizacao ON propriedade (tenant_id, data_atualizacao);
CREATE INDEX idx_animal_tenant_data_atualizacao ON animal (tenant_id, data_atualizacao);
CREATE INDEX idx_visita_tenant_data_atualizacao ON visita (tenant_id, data_atualizacao);
CREATE INDEX idx_evento_reprodutivo_tenant_data_atualizacao ON evento_reprodutivo (tenant_id, data_atualizacao);
CREATE INDEX idx_registro_excluido_tenant_data_atualizacao ON registro_excluido (tenant_id, data_atualizacao);
