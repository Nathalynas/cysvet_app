SELECT
    schema_name,
    default_character_set_name,
    default_collation_name
FROM information_schema.schemata
WHERE schema_name = DATABASE();

SELECT
    table_name,
    table_collation
FROM information_schema.tables
WHERE table_schema = DATABASE()
  AND table_type = 'BASE TABLE'
  AND table_collation <> 'utf8mb4_unicode_ci';

SELECT
    table_name,
    column_name,
    character_set_name,
    collation_name
FROM information_schema.columns
WHERE table_schema = DATABASE()
  AND data_type IN ('char', 'varchar', 'text', 'mediumtext', 'longtext')
  AND (
    character_set_name <> 'utf8mb4'
    OR collation_name <> 'utf8mb4_unicode_ci'
  );
