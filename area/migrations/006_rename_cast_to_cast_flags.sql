-- Migration 006: Rename mobiles."cast" to cast_flags
--
-- The column "cast" was quoted to avoid the SQL reserved word CAST.
-- The canonical acktng schema.sql uses cast_flags instead.
--
-- Apply with:
--   psql -U ack -d acktng -f area/migrations/006_rename_cast_to_cast_flags.sql

BEGIN;

ALTER TABLE mobiles RENAME COLUMN "cast" TO cast_flags;

INSERT INTO schema_version (version, description)
    VALUES (6, 'Rename mobiles."cast" to cast_flags to match canonical schema');

COMMIT;
