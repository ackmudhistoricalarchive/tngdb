-- ACK!TNG PostgreSQL schema
-- Apply with: psql -U ack -d acktng -f area/schema.sql

-- ---------------------------------------------------------------------------
-- Area content
-- ---------------------------------------------------------------------------

CREATE TABLE areas (
    id           SERIAL  PRIMARY KEY,
    name         TEXT    NOT NULL,
    min_vnum     INTEGER NOT NULL,
    max_vnum     INTEGER NOT NULL,
    keyword      TEXT,
    level_label  TEXT,
    area_number  INTEGER,
    level_min    INTEGER,
    level_max    INTEGER,
    map_offset   INTEGER,
    reset_rate   INTEGER,
    reset_msg    TEXT,
    owner        TEXT,
    can_read     TEXT,
    can_write    TEXT,
    music        TEXT,
    flags        INTEGER NOT NULL DEFAULT 0,
    UNIQUE(min_vnum),
    UNIQUE(max_vnum),
    CHECK(min_vnum <= max_vnum)
);

CREATE TABLE rooms (
    vnum         INTEGER PRIMARY KEY,
    area_id      INTEGER NOT NULL REFERENCES areas(id),
    name         TEXT    NOT NULL,
    description  TEXT    NOT NULL,
    room_flags   INTEGER NOT NULL DEFAULT 0,
    sector_type  INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE room_exits (
    id           SERIAL  PRIMARY KEY,
    room_vnum    INTEGER NOT NULL REFERENCES rooms(vnum),
    direction    INTEGER NOT NULL,
    dest_vnum    INTEGER,
    exit_flags   INTEGER NOT NULL DEFAULT 0,
    key_vnum     INTEGER,
    keyword      TEXT,
    description  TEXT,
    UNIQUE(room_vnum, direction)
);

CREATE TABLE room_extra_descs (
    id           SERIAL  PRIMARY KEY,
    room_vnum    INTEGER NOT NULL REFERENCES rooms(vnum),
    keyword      TEXT    NOT NULL,
    description  TEXT    NOT NULL
);

CREATE TABLE mobiles (
    vnum          INTEGER PRIMARY KEY,
    area_id       INTEGER NOT NULL REFERENCES areas(id),
    player_name   TEXT    NOT NULL,
    short_descr   TEXT    NOT NULL,
    long_descr    TEXT    NOT NULL,
    description   TEXT    NOT NULL,
    act_flags     BIGINT  NOT NULL DEFAULT 0,
    affected_by   INTEGER NOT NULL DEFAULT 0,
    alignment     INTEGER NOT NULL DEFAULT 0,
    level         INTEGER NOT NULL DEFAULT 1,
    sex           INTEGER NOT NULL DEFAULT 0,
    hp_mod        INTEGER NOT NULL DEFAULT 0,
    ac_mod        INTEGER NOT NULL DEFAULT 0,
    hr_mod        INTEGER NOT NULL DEFAULT 0,
    dr_mod        INTEGER NOT NULL DEFAULT 0,
    class         INTEGER NOT NULL DEFAULT 0,
    clan          INTEGER NOT NULL DEFAULT 0,
    race          INTEGER NOT NULL DEFAULT 0,
    position      INTEGER NOT NULL DEFAULT 0,
    skills        INTEGER NOT NULL DEFAULT 0,
    "cast"        INTEGER NOT NULL DEFAULT 0,
    def           INTEGER NOT NULL DEFAULT 0,
    strong_magic  INTEGER NOT NULL DEFAULT 0,
    weak_magic    INTEGER NOT NULL DEFAULT 0,
    race_mods     INTEGER NOT NULL DEFAULT 0,
    power_skills  INTEGER NOT NULL DEFAULT 0,
    power_cast    INTEGER NOT NULL DEFAULT 0,
    resist        INTEGER NOT NULL DEFAULT 0,
    suscept       INTEGER NOT NULL DEFAULT 0,
    spellpower    INTEGER NOT NULL DEFAULT 0,
    crit          INTEGER NOT NULL DEFAULT 0,
    crit_mult     INTEGER NOT NULL DEFAULT 0,
    spell_crit    INTEGER NOT NULL DEFAULT 0,
    spell_mult    INTEGER NOT NULL DEFAULT 0,
    parry         INTEGER NOT NULL DEFAULT 0,
    dodge         INTEGER NOT NULL DEFAULT 0,
    block         INTEGER NOT NULL DEFAULT 0,
    pierce        INTEGER NOT NULL DEFAULT 0,
    ai_knowledge  INTEGER NOT NULL DEFAULT 0,
    accent        TEXT,
    ai_prompt     TEXT,
    loot_amount   INTEGER NOT NULL DEFAULT 0,
    loot_0        INTEGER NOT NULL DEFAULT 0,
    loot_1        INTEGER NOT NULL DEFAULT 0,
    loot_2        INTEGER NOT NULL DEFAULT 0,
    loot_3        INTEGER NOT NULL DEFAULT 0,
    loot_4        INTEGER NOT NULL DEFAULT 0,
    loot_5        INTEGER NOT NULL DEFAULT 0,
    loot_6        INTEGER NOT NULL DEFAULT 0,
    loot_7        INTEGER NOT NULL DEFAULT 0,
    loot_8        INTEGER NOT NULL DEFAULT 0,
    loot_chance_0 INTEGER NOT NULL DEFAULT 0,
    loot_chance_1 INTEGER NOT NULL DEFAULT 0,
    loot_chance_2 INTEGER NOT NULL DEFAULT 0,
    loot_chance_3 INTEGER NOT NULL DEFAULT 0,
    loot_chance_4 INTEGER NOT NULL DEFAULT 0,
    loot_chance_5 INTEGER NOT NULL DEFAULT 0,
    loot_chance_6 INTEGER NOT NULL DEFAULT 0,
    loot_chance_7 INTEGER NOT NULL DEFAULT 0,
    loot_chance_8 INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE objects (
    vnum         INTEGER PRIMARY KEY,
    area_id      INTEGER NOT NULL REFERENCES areas(id),
    name         TEXT    NOT NULL,
    short_descr  TEXT    NOT NULL,
    description  TEXT    NOT NULL,
    item_type    INTEGER NOT NULL,
    extra_flags  BIGINT  NOT NULL DEFAULT 0,
    wear_flags   INTEGER NOT NULL DEFAULT 0,
    item_apply   INTEGER NOT NULL DEFAULT 0,
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
    weight       INTEGER NOT NULL DEFAULT 0,
    level        INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE object_extra_descs (
    id           SERIAL  PRIMARY KEY,
    obj_vnum     INTEGER NOT NULL REFERENCES objects(vnum),
    keyword      TEXT    NOT NULL,
    description  TEXT    NOT NULL
);

CREATE TABLE object_affects (
    id           SERIAL  PRIMARY KEY,
    obj_vnum     INTEGER NOT NULL REFERENCES objects(vnum),
    location     INTEGER NOT NULL,
    modifier     INTEGER NOT NULL
);

CREATE TABLE shops (
    id           SERIAL  PRIMARY KEY,
    keeper_vnum  INTEGER NOT NULL REFERENCES mobiles(vnum),
    buy_type_0   INTEGER NOT NULL DEFAULT 0,
    buy_type_1   INTEGER NOT NULL DEFAULT 0,
    buy_type_2   INTEGER NOT NULL DEFAULT 0,
    buy_type_3   INTEGER NOT NULL DEFAULT 0,
    buy_type_4   INTEGER NOT NULL DEFAULT 0,
    profit_buy   INTEGER NOT NULL DEFAULT 100,
    profit_sell  INTEGER NOT NULL DEFAULT 100,
    open_hour    INTEGER NOT NULL DEFAULT 0,
    close_hour   INTEGER NOT NULL DEFAULT 23,
    UNIQUE(keeper_vnum)
);

CREATE TABLE resets (
    id           SERIAL PRIMARY KEY,
    area_id      INTEGER NOT NULL REFERENCES areas(id),
    seq          INTEGER NOT NULL,
    command      CHAR(1) NOT NULL CHECK(command IN ('M','O','G','E','D','R','P','A')),
    ifflag       INTEGER NOT NULL DEFAULT 0,
    arg1         INTEGER NOT NULL DEFAULT 0,
    arg2         INTEGER NOT NULL DEFAULT 0,
    arg3         INTEGER NOT NULL DEFAULT 0,
    notes        TEXT,
    auto_msg     TEXT,
    UNIQUE(area_id, seq)
);

CREATE TABLE mobile_specials (
    mob_vnum     INTEGER PRIMARY KEY REFERENCES mobiles(vnum),
    spec_name    TEXT    NOT NULL
);

-- Per-mobile AI script storage (extended prompts beyond the inline ai_prompt)
CREATE TABLE mob_scripts (
    mob_vnum     INTEGER PRIMARY KEY REFERENCES mobiles(vnum),
    prompt       TEXT    NOT NULL DEFAULT ''
);

CREATE TABLE object_functions (
    obj_vnum     INTEGER PRIMARY KEY REFERENCES objects(vnum),
    func_name    TEXT    NOT NULL
);

-- ---------------------------------------------------------------------------
-- Help systems
-- ---------------------------------------------------------------------------

CREATE TABLE help_entries (
    id           SERIAL  PRIMARY KEY,
    keyword      TEXT    NOT NULL,
    title        TEXT    NOT NULL DEFAULT '',
    level        INTEGER NOT NULL DEFAULT 0,
    text         TEXT    NOT NULL,
    textsearch   tsvector GENERATED ALWAYS AS (
                       setweight(to_tsvector('english', coalesce(keyword, '')), 'A')
                    || setweight(to_tsvector('english', coalesce(title,   '')), 'B')
                    || setweight(to_tsvector('english', coalesce(text,    '')), 'C')
                 ) STORED
);

CREATE TABLE shelp_entries (
    id           SERIAL  PRIMARY KEY,
    keyword      TEXT    NOT NULL,
    title        TEXT    NOT NULL DEFAULT '',
    level        INTEGER NOT NULL DEFAULT 0,
    text         TEXT    NOT NULL,
    textsearch   tsvector GENERATED ALWAYS AS (
                       setweight(to_tsvector('english', coalesce(keyword, '')), 'A')
                    || setweight(to_tsvector('english', coalesce(title,   '')), 'B')
                    || setweight(to_tsvector('english', coalesce(text,    '')), 'C')
                 ) STORED
);

-- ---------------------------------------------------------------------------
-- Lore
-- ---------------------------------------------------------------------------

CREATE TABLE lore_topics (
    id           SERIAL PRIMARY KEY,
    name         TEXT   NOT NULL UNIQUE,
    keyword      TEXT   NOT NULL,
    description  TEXT   NOT NULL DEFAULT '',
    textsearch   tsvector GENERATED ALWAYS AS (
                       setweight(to_tsvector('english', coalesce(keyword,     '')), 'A')
                    || setweight(to_tsvector('english', coalesce(name,        '')), 'B')
                    || setweight(to_tsvector('english', coalesce(description, '')), 'C')
                 ) STORED
);

CREATE TABLE lore_entries (
    id           SERIAL  PRIMARY KEY,
    topic_id     INTEGER NOT NULL REFERENCES lore_topics(id),
    seq          INTEGER NOT NULL,
    keyword      TEXT    NOT NULL DEFAULT '',
    text         TEXT    NOT NULL,
    UNIQUE(topic_id, seq)
);

-- ---------------------------------------------------------------------------
-- Runtime state (data/)
-- ---------------------------------------------------------------------------

CREATE TABLE bans (
    id           SERIAL  PRIMARY KEY,
    type         INTEGER NOT NULL DEFAULT 0,
    value        TEXT    NOT NULL,
    reason       TEXT    NOT NULL DEFAULT '',
    date         TEXT    NOT NULL DEFAULT ''
);

CREATE TABLE socials (
    id            SERIAL PRIMARY KEY,
    name          TEXT   NOT NULL UNIQUE,
    char_no_arg   TEXT   NOT NULL DEFAULT '',
    others_no_arg TEXT   NOT NULL DEFAULT '',
    char_found    TEXT   NOT NULL DEFAULT '',
    others_found  TEXT   NOT NULL DEFAULT '',
    vict_found    TEXT   NOT NULL DEFAULT '',
    char_auto     TEXT   NOT NULL DEFAULT '',
    others_auto   TEXT   NOT NULL DEFAULT ''
);

CREATE TABLE boards (
    id           SERIAL  PRIMARY KEY,
    obj_vnum     INTEGER NOT NULL,
    name         TEXT    NOT NULL,
    read_level   INTEGER NOT NULL DEFAULT 0,
    post_level   INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE board_messages (
    id           SERIAL  PRIMARY KEY,
    board_id     INTEGER NOT NULL REFERENCES boards(id),
    author       TEXT    NOT NULL DEFAULT '',
    timestamp    TEXT    NOT NULL DEFAULT '',
    subject      TEXT    NOT NULL DEFAULT '',
    text         TEXT    NOT NULL DEFAULT ''
);

CREATE TABLE clans (
    id           INTEGER PRIMARY KEY,
    name         TEXT    NOT NULL DEFAULT '',
    leader       TEXT    NOT NULL DEFAULT '',
    treasury     INTEGER NOT NULL DEFAULT 0,
    flags        INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE rulers (
    id           SERIAL  PRIMARY KEY,
    clan_id      INTEGER NOT NULL REFERENCES clans(id),
    position     TEXT    NOT NULL,
    player_name  TEXT    NOT NULL
);

CREATE TABLE brands (
    id           SERIAL  PRIMARY KEY,
    owner        TEXT    NOT NULL,
    obj_vnum     INTEGER NOT NULL,
    timestamp    TEXT    NOT NULL DEFAULT ''
);

CREATE TABLE room_marks (
    id           SERIAL  PRIMARY KEY,
    room_vnum    INTEGER NOT NULL,
    player_name  TEXT    NOT NULL DEFAULT '',
    mark_text    TEXT    NOT NULL
);

CREATE TABLE corpses (
    id           SERIAL  PRIMARY KEY,
    obj_vnum     INTEGER NOT NULL DEFAULT 0,
    owner        TEXT    NOT NULL DEFAULT '',
    room_vnum    INTEGER NOT NULL,
    created_at   TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    contents     JSONB   NOT NULL DEFAULT '[]'
);

-- Key-value store for global server state and messages
CREATE TABLE sysdata (
    key          TEXT PRIMARY KEY,
    value        TEXT NOT NULL DEFAULT ''
);

-- ---------------------------------------------------------------------------
-- Players
-- ---------------------------------------------------------------------------

CREATE TABLE players (
    id           SERIAL    PRIMARY KEY,
    name         TEXT      NOT NULL UNIQUE,
    pwd_hash     TEXT      NOT NULL,
    title        TEXT      NOT NULL DEFAULT '',
    description  TEXT      NOT NULL DEFAULT '',
    race         INTEGER   NOT NULL DEFAULT 0,
    sex          INTEGER   NOT NULL DEFAULT 0,
    class        INTEGER   NOT NULL DEFAULT 0,
    level        INTEGER   NOT NULL DEFAULT 0,
    trust        INTEGER   NOT NULL DEFAULT 0,
    played       INTEGER   NOT NULL DEFAULT 0,
    last_login   TIMESTAMP WITH TIME ZONE,
    hit          INTEGER   NOT NULL DEFAULT 0,
    max_hit      INTEGER   NOT NULL DEFAULT 0,
    mana         INTEGER   NOT NULL DEFAULT 0,
    max_mana     INTEGER   NOT NULL DEFAULT 0,
    move         INTEGER   NOT NULL DEFAULT 0,
    max_move     INTEGER   NOT NULL DEFAULT 0,
    gold         INTEGER   NOT NULL DEFAULT 0,
    exp          INTEGER   NOT NULL DEFAULT 0,
    act_flags    BIGINT    NOT NULL DEFAULT 0,
    affected_by  INTEGER   NOT NULL DEFAULT 0,
    position     INTEGER   NOT NULL DEFAULT 0,
    practice     INTEGER   NOT NULL DEFAULT 0,
    quest_points INTEGER   NOT NULL DEFAULT 0,
    str          INTEGER   NOT NULL DEFAULT 0,
    int_         INTEGER   NOT NULL DEFAULT 0,
    wis          INTEGER   NOT NULL DEFAULT 0,
    dex          INTEGER   NOT NULL DEFAULT 0,
    con          INTEGER   NOT NULL DEFAULT 0,
    str_mod      INTEGER   NOT NULL DEFAULT 0,
    int_mod      INTEGER   NOT NULL DEFAULT 0,
    wis_mod      INTEGER   NOT NULL DEFAULT 0,
    dex_mod      INTEGER   NOT NULL DEFAULT 0,
    con_mod      INTEGER   NOT NULL DEFAULT 0,
    skills       JSONB     NOT NULL DEFAULT '{}',
    affects      JSONB     NOT NULL DEFAULT '[]',
    inventory    JSONB     NOT NULL DEFAULT '[]',
    raw_save     TEXT
);

-- ---------------------------------------------------------------------------
-- Indexes
-- ---------------------------------------------------------------------------

CREATE INDEX ON rooms(area_id);
CREATE INDEX ON room_exits(room_vnum);
CREATE INDEX ON room_extra_descs(room_vnum);
CREATE INDEX ON mobiles(area_id);
CREATE INDEX ON objects(area_id);
CREATE INDEX ON object_extra_descs(obj_vnum);
CREATE INDEX ON object_affects(obj_vnum);
CREATE INDEX ON resets(area_id, seq);
CREATE INDEX ON lore_entries(topic_id);
CREATE INDEX ON board_messages(board_id);
CREATE INDEX ON corpses(room_vnum);

-- Full-text search (weighted: keyword=A, title/name=B, body=C)
CREATE INDEX help_entries_textsearch_idx  ON help_entries  USING GIN (textsearch);
CREATE INDEX shelp_entries_textsearch_idx ON shelp_entries USING GIN (textsearch);
CREATE INDEX lore_topics_textsearch_idx   ON lore_topics   USING GIN (textsearch);

-- ---------------------------------------------------------------------------
-- Schema version
-- ---------------------------------------------------------------------------

CREATE TABLE schema_version (
    version     INTEGER                  NOT NULL,
    applied_at  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    description TEXT                     NOT NULL DEFAULT ''
);

INSERT INTO schema_version (version, description)
    VALUES (2, 'Align schema with database-schema-areas proposal');
INSERT INTO schema_version (version, description)
    VALUES (3, 'Add stored tsvector columns for weighted full-text search');
