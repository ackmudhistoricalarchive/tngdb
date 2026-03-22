-- Migration 004: Align brands table with canonical acktng schema; add keep_chests tables
--
-- PR #920 (acktng) changed brands.brand_date from TIMESTAMP WITH TIME ZONE to TEXT
-- to match the actual ctime(3)-formatted strings stored by the game server.
--
-- The tngdb brands table had diverged from the canonical acktng schema (it used
-- owner/obj_vnum/timestamp instead of branded_by/item_name/brand_date/description).
-- This migration brings it in line with what the game server reads and writes.
--
-- Also adds keep_chests and keep_chest_items tables introduced in PR #913.
--
-- Apply with:
--   psql -U ack -d acktng -f area/migrations/004_brands_align_and_keep_chests.sql

BEGIN;

-- ---------------------------------------------------------------------------
-- Rebuild brands to match canonical acktng schema
-- brand_date is TEXT (ctime(3) formatted) per PR #920
-- ---------------------------------------------------------------------------

DROP TABLE IF EXISTS brands;

CREATE TABLE brands (
    id           SERIAL PRIMARY KEY,
    branded_by   TEXT   NOT NULL,
    item_name    TEXT   NOT NULL,
    brand_date   TEXT   NOT NULL DEFAULT '',
    description  TEXT   NOT NULL DEFAULT ''
);

-- ---------------------------------------------------------------------------
-- keep_chests (introduced in acktng PR #913)
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS keep_chests (
    id           SERIAL  PRIMARY KEY,
    vnum         INTEGER NOT NULL UNIQUE,
    owner_name   TEXT    NOT NULL,
    max_items    INTEGER NOT NULL DEFAULT 50,
    created_at   TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at   TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- ---------------------------------------------------------------------------
-- keep_chest_items (introduced in acktng PR #913)
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS keep_chest_items (
    id           SERIAL  PRIMARY KEY,
    chest_id     INTEGER NOT NULL REFERENCES keep_chests(id) ON DELETE CASCADE,
    nest         INTEGER NOT NULL DEFAULT 0,
    parent_id    INTEGER REFERENCES keep_chest_items(id),
    name         TEXT    NOT NULL,
    short_descr  TEXT    NOT NULL,
    description  TEXT    NOT NULL,
    vnum         INTEGER NOT NULL DEFAULT 0,
    extra_flags  BIGINT  NOT NULL DEFAULT 0,
    wear_flags   INTEGER NOT NULL DEFAULT 0,
    wear_loc     INTEGER NOT NULL DEFAULT -1,
    class_flags  INTEGER NOT NULL DEFAULT 0,
    item_type    INTEGER NOT NULL DEFAULT 0,
    weight       INTEGER NOT NULL DEFAULT 0,
    level        INTEGER NOT NULL DEFAULT 0,
    timer        INTEGER NOT NULL DEFAULT -1,
    cost         INTEGER NOT NULL DEFAULT 0,
    value_0      INTEGER NOT NULL DEFAULT 0,
    value_1      INTEGER NOT NULL DEFAULT 0,
    value_2      INTEGER NOT NULL DEFAULT 0,
    value_3      INTEGER NOT NULL DEFAULT 0,
    value_4      INTEGER NOT NULL DEFAULT 0,
    value_5      INTEGER NOT NULL DEFAULT 0,
    value_6      INTEGER NOT NULL DEFAULT 0,
    value_7      INTEGER NOT NULL DEFAULT 0,
    value_8      INTEGER NOT NULL DEFAULT 0,
    value_9      INTEGER NOT NULL DEFAULT 0,
    objfun       TEXT,
    sort_order   INTEGER NOT NULL DEFAULT 0
);

-- ---------------------------------------------------------------------------
-- Schema version
-- ---------------------------------------------------------------------------

INSERT INTO schema_version (version, description)
    VALUES (4, 'Align brands with acktng canonical schema (brand_date TEXT per PR #920); add keep_chests tables');

COMMIT;
