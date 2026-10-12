-- Troca obrigatoria de senha (senha provisoria enviada pelo super usuario).
ALTER TABLE usuario ADD COLUMN trocar_senha BOOLEAN NOT NULL DEFAULT FALSE;

-- Usuario responsavel pela empresa (criado pelo super usuario). Empresas
-- antigas recebem o ADMIN mais antigo vinculado, se houver.
ALTER TABLE empresa ADD COLUMN responsavel_usuario_id BIGINT NULL;
ALTER TABLE empresa ADD CONSTRAINT fk_empresa_responsavel
    FOREIGN KEY (responsavel_usuario_id) REFERENCES usuario (id);

UPDATE empresa
SET responsavel_usuario_id = (
    SELECT MIN(u.id)
    FROM usuario_empresa ue
    JOIN usuario u ON u.id = ue.id_usuario
    WHERE ue.id_empresa = empresa.id AND u.perfil = 'ADMIN'
);
