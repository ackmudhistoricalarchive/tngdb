-- Migration 005: Align all tables with the canonical acktng schema.sql proposal
--
-- This migration brings the tngdb schema into full alignment with
-- docs/proposals/schema.sql in the acktng repository.
--
-- Tables rebuilt or significantly altered:
--   mobiles         — accent column: TEXT → INTEGER
--   object_functions — func_name renamed to fun_name
--   mob_scripts     — single-prompt row → sequence-based trigger/commands rows
--   help_entries    — keyword/title/text/textsearch → filename/level/keywords/body
--   shelp_entries   — same
--   lore_topics     — name/keyword/description/textsearch → filename/keywords
--   lore_entries    — keyword/text → flags/body
--   bans            — type/value/reason/date → ban_type/address/banned_by
--   boards          — obj_vnum/name/read_level/post_level → vnum/expiry_days/min_read_lev/min_write_lev/clan
--   board_messages  — timestamp/subject/text → posted_at(BIGINT)/title/body/seq
--   clans           — leader/treasury/flags → war_count/win_count/loss_count/member_count/gold/war_matrix
--   rulers          — clan_id/position/player_name → name only
--   room_marks      — drop player_name column
--   corpses         — JSONB contents blob → flat per-item rows with parent_id
--   sysdata         — key/value store → structured singleton row
--
-- Apply with:
--   psql -U ack -d acktng -f area/migrations/005_align_canonical_schema.sql

BEGIN;

-- ---------------------------------------------------------------------------
-- mobiles: accent TEXT → INTEGER NOT NULL DEFAULT 0
-- ---------------------------------------------------------------------------

ALTER TABLE mobiles
    ALTER COLUMN accent TYPE INTEGER USING 0,
    ALTER COLUMN accent SET NOT NULL,
    ALTER COLUMN accent SET DEFAULT 0;

-- ---------------------------------------------------------------------------
-- object_functions: rename func_name → fun_name
-- ---------------------------------------------------------------------------

ALTER TABLE object_functions RENAME COLUMN func_name TO fun_name;

-- ---------------------------------------------------------------------------
-- mob_scripts: rebuild as sequence-based trigger/commands table
-- Old schema had a single row per mob with a prompt TEXT blob.
-- Canonical schema has one row per script step (mob_vnum, seq, trigger, args, commands).
-- ---------------------------------------------------------------------------

DROP TABLE IF EXISTS mob_scripts;

CREATE TABLE mob_scripts (
    id       SERIAL  PRIMARY KEY,
    mob_vnum INTEGER NOT NULL REFERENCES mobiles (vnum),
    seq      INTEGER NOT NULL,
    trigger  TEXT    NOT NULL,
    args     TEXT    NOT NULL DEFAULT '',
    commands TEXT    NOT NULL,
    UNIQUE (mob_vnum, seq)
);

-- ---------------------------------------------------------------------------
-- help_entries: replace tsvector-weighted schema with file-based schema
-- ---------------------------------------------------------------------------

DROP TABLE IF EXISTS help_entries;

CREATE TABLE help_entries (
    id       SERIAL  PRIMARY KEY,
    filename TEXT    NOT NULL UNIQUE,
    level    INTEGER NOT NULL,
    keywords TEXT    NOT NULL,
    body     TEXT    NOT NULL
);

-- ---------------------------------------------------------------------------
-- shelp_entries: same as help_entries
-- ---------------------------------------------------------------------------

DROP TABLE IF EXISTS shelp_entries;

CREATE TABLE shelp_entries (
    id       SERIAL  PRIMARY KEY,
    filename TEXT    NOT NULL UNIQUE,
    level    INTEGER NOT NULL,
    keywords TEXT    NOT NULL,
    body     TEXT    NOT NULL
);

-- ---------------------------------------------------------------------------
-- lore_topics / lore_entries: rebuild with canonical columns
-- lore_entries references lore_topics so drop child first
-- ---------------------------------------------------------------------------

DROP TABLE IF EXISTS lore_entries;
DROP TABLE IF EXISTS lore_topics;

CREATE TABLE lore_topics (
    id       SERIAL PRIMARY KEY,
    filename TEXT   NOT NULL UNIQUE,
    keywords TEXT   NOT NULL
);

CREATE TABLE lore_entries (
    id       SERIAL  PRIMARY KEY,
    topic_id INTEGER NOT NULL REFERENCES lore_topics (id),
    seq      INTEGER NOT NULL,
    flags    BIGINT  NOT NULL DEFAULT 0,
    body     TEXT    NOT NULL,
    UNIQUE (topic_id, seq)
);

-- ---------------------------------------------------------------------------
-- bans: rename columns to match canonical schema
-- ---------------------------------------------------------------------------

DROP TABLE IF EXISTS bans;

CREATE TABLE bans (
    id        SERIAL  PRIMARY KEY,
    ban_type  INTEGER NOT NULL DEFAULT 0,
    address   TEXT    NOT NULL,
    banned_by TEXT    NOT NULL DEFAULT ''
);

-- ---------------------------------------------------------------------------
-- boards / board_messages: rebuild with canonical columns
-- board_messages references boards so drop child first
-- ---------------------------------------------------------------------------

DROP TABLE IF EXISTS board_messages;
DROP TABLE IF EXISTS boards;

CREATE TABLE boards (
    id            SERIAL  PRIMARY KEY,
    vnum          INTEGER NOT NULL UNIQUE,
    expiry_days   INTEGER NOT NULL DEFAULT 10,
    min_read_lev  INTEGER NOT NULL DEFAULT 0,
    min_write_lev INTEGER NOT NULL DEFAULT 0,
    clan          INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE board_messages (
    id        SERIAL  PRIMARY KEY,
    board_id  INTEGER NOT NULL REFERENCES boards (id) ON DELETE CASCADE,
    posted_at BIGINT  NOT NULL,
    author    TEXT    NOT NULL,
    title     TEXT    NOT NULL DEFAULT '',
    body      TEXT    NOT NULL DEFAULT '',
    seq       INTEGER NOT NULL
);

CREATE INDEX board_messages_board_id_seq ON board_messages (board_id, seq);

-- ---------------------------------------------------------------------------
-- clans / rulers: rebuild with canonical columns
-- rulers had a FK on clans so drop child first
-- ---------------------------------------------------------------------------

DROP TABLE IF EXISTS rulers;
DROP TABLE IF EXISTS clans;

CREATE TABLE clans (
    id           INTEGER   PRIMARY KEY,
    name         TEXT      NOT NULL DEFAULT '',
    war_count    INTEGER   NOT NULL DEFAULT 0,
    win_count    INTEGER   NOT NULL DEFAULT 0,
    loss_count   INTEGER   NOT NULL DEFAULT 0,
    member_count INTEGER   NOT NULL DEFAULT 0,
    gold         INTEGER   NOT NULL DEFAULT 0,
    war_matrix   INTEGER[] NOT NULL DEFAULT '{}'
);

-- Canonical rulers table: just a name list (titles/positions stored in C layer)
CREATE TABLE rulers (
    id   SERIAL PRIMARY KEY,
    name TEXT   NOT NULL UNIQUE
);

-- ---------------------------------------------------------------------------
-- room_marks: drop player_name (not present in canonical schema)
-- ---------------------------------------------------------------------------

ALTER TABLE room_marks DROP COLUMN IF EXISTS player_name;

-- ---------------------------------------------------------------------------
-- corpses: rebuild as flat per-item rows (canonical schema)
-- Old schema stored contents as a JSONB blob; canonical schema uses one row
-- per item with a self-referential parent_id for nesting.
-- ---------------------------------------------------------------------------

DROP TABLE IF EXISTS corpses;

CREATE TABLE corpses (
    id          SERIAL  PRIMARY KEY,
    where_vnum  INTEGER NOT NULL,
    nest        INTEGER NOT NULL DEFAULT 0,
    name        TEXT    NOT NULL,
    short_descr TEXT    NOT NULL,
    description TEXT    NOT NULL,
    vnum        INTEGER NOT NULL DEFAULT 0,
    extra_flags BIGINT  NOT NULL DEFAULT 0,
    wear_flags  INTEGER NOT NULL DEFAULT 0,
    wear_loc    INTEGER NOT NULL DEFAULT -1,
    class_flags INTEGER NOT NULL DEFAULT 0,
    item_type   INTEGER NOT NULL DEFAULT 0,
    weight      INTEGER NOT NULL DEFAULT 0,
    level       INTEGER NOT NULL DEFAULT 0,
    timer       INTEGER NOT NULL DEFAULT 0,
    cost        INTEGER NOT NULL DEFAULT 0,
    value_0     INTEGER NOT NULL DEFAULT 0,
    value_1     INTEGER NOT NULL DEFAULT 0,
    value_2     INTEGER NOT NULL DEFAULT 0,
    value_3     INTEGER NOT NULL DEFAULT 0,
    value_4     INTEGER NOT NULL DEFAULT 0,
    value_5     INTEGER NOT NULL DEFAULT 0,
    value_6     INTEGER NOT NULL DEFAULT 0,
    value_7     INTEGER NOT NULL DEFAULT 0,
    value_8     INTEGER NOT NULL DEFAULT 0,
    value_9     INTEGER NOT NULL DEFAULT 0,
    parent_id   INTEGER REFERENCES corpses (id)
);

-- ---------------------------------------------------------------------------
-- sysdata: rebuild as structured singleton (canonical schema)
-- Old schema was a generic key/value store; canonical schema is a single row
-- with named columns for each configuration field.
-- ---------------------------------------------------------------------------

DROP TABLE IF EXISTS sysdata;

CREATE TABLE sysdata (
    id          INTEGER PRIMARY KEY DEFAULT 1 CHECK (id = 1),
    mud_name    TEXT    NOT NULL DEFAULT '',
    admin_email TEXT    NOT NULL DEFAULT '',
    login_msg   TEXT    NOT NULL DEFAULT '',
    motd        TEXT    NOT NULL DEFAULT '',
    welcome     TEXT    NOT NULL DEFAULT '',
    news        TEXT    NOT NULL DEFAULT '',
    int_val_1   INTEGER NOT NULL DEFAULT 0,
    int_val_2   INTEGER NOT NULL DEFAULT 0,
    bln_val_0   INTEGER NOT NULL DEFAULT 0,
    bln_val_1   INTEGER NOT NULL DEFAULT 0,
    bln_val_2   INTEGER NOT NULL DEFAULT 0,
    bln_val_3   INTEGER NOT NULL DEFAULT 0,
    bln_val_4   INTEGER NOT NULL DEFAULT 0,
    bln_val_5   INTEGER NOT NULL DEFAULT 0,
    bln_val_6   INTEGER NOT NULL DEFAULT 0,
    bln_val_7   INTEGER NOT NULL DEFAULT 0
);

INSERT INTO sysdata (id) VALUES (1) ON CONFLICT (id) DO NOTHING;

-- ---------------------------------------------------------------------------
-- Indexes: rebuild affected tables' indexes
-- ---------------------------------------------------------------------------

CREATE INDEX ON lore_entries (topic_id);
CREATE INDEX ON corpses (where_vnum);

-- ---------------------------------------------------------------------------
-- Schema version
-- ---------------------------------------------------------------------------

INSERT INTO schema_version (version, description)
    VALUES (5, 'Align all tables with canonical acktng schema.sql proposal');

COMMIT;
