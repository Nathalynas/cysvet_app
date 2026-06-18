ALTER TABLE animal
    ADD COLUMN data_inseminacao DATE NULL AFTER data_ultimo_parto;

UPDATE animal
SET data_inseminacao = (
    SELECT MAX(e.data_evento)
    FROM evento_reprodutivo e
    WHERE e.id_animal = animal.id
      AND e.tipo = 'INSEMINATION'
)
WHERE data_inseminacao IS NULL;
