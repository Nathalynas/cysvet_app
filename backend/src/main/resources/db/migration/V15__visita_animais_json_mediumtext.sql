-- A coleta de cada animal da visita ocupa ~1,3 KB em JSON. O TEXT do MySQL
-- guarda ate 64 KB, o que estoura por volta de 50 animais; visitas reais
-- avaliam o rebanho inteiro (~300 animais). MEDIUMTEXT comporta ate 16 MB.
ALTER TABLE visita MODIFY COLUMN animais_json MEDIUMTEXT NULL;
