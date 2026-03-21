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
    vnum         INTEGER PRIMARY KEY,
    area_id      INTEGER NOT NULL REFERENCES areas(id),
    player_name  TEXT    NOT NULL,
    short_descr  TEXT    NOT NULL,
    long_descr   TEXT    NOT NULL,
    description  TEXT    NOT NULL,
    act_flags    BIGINT  NOT NULL DEFAULT 0,
    affected_by  INTEGER NOT NULL DEFAULT 0,
    alignment    INTEGER NOT NULL DEFAULT 0,
    level        INTEGER NOT NULL DEFAULT 1,
    sex          INTEGER NOT NULL DEFAULT 0,
    hp_mod       INTEGER NOT NULL DEFAULT 0,
    ac_mod       INTEGER NOT NULL DEFAULT 0,
    hr_mod       INTEGER NOT NULL DEFAULT 0,
    dr_mod       INTEGER NOT NULL DEFAULT 0,
    class        INTEGER NOT NULL DEFAULT 0,
    clan         INTEGER NOT NULL DEFAULT 0,
    race         INTEGER NOT NULL DEFAULT 0,
    position     INTEGER NOT NULL DEFAULT 0,
    skills       INTEGER NOT NULL DEFAULT 0,
    cast         INTEGER NOT NULL DEFAULT 0,
    def          INTEGER NOT NULL DEFAULT 0,
    strong_magic INTEGER NOT NULL DEFAULT 0,
    weak_magic   INTEGER NOT NULL DEFAULT 0,
    race_mods    INTEGER NOT NULL DEFAULT 0,
    power_skills INTEGER NOT NULL DEFAULT 0,
    power_cast   INTEGER NOT NULL DEFAULT 0,
    resist       INTEGER NOT NULL DEFAULT 0,
    suscept      INTEGER NOT NULL DEFAULT 0,
    spellpower   INTEGER NOT NULL DEFAULT 0,
    crit         INTEGER NOT NULL DEFAULT 0,
    crit_mult    INTEGER NOT NULL DEFAULT 0,
    spell_crit   INTEGER NOT NULL DEFAULT 0,
    spell_mult   INTEGER NOT NULL DEFAULT 0,
    parry        INTEGER NOT NULL DEFAULT 0,
    dodge        INTEGER NOT NULL DEFAULT 0,
    block        INTEGER NOT NULL DEFAULT 0,
    pierce       INTEGER NOT NULL DEFAULT 0,
    ai_knowledge INTEGER NOT NULL DEFAULT 0,
    ai_prompt    TEXT,
    loot_amount  INTEGER NOT NULL DEFAULT 0,
    loot_0       INTEGER NOT NULL DEFAULT 0,
    loot_1       INTEGER NOT NULL DEFAULT 0,
    loot_2       INTEGER NOT NULL DEFAULT 0,
    loot_3       INTEGER NOT NULL DEFAULT 0,
    loot_4       INTEGER NOT NULL DEFAULT 0,
    loot_5       INTEGER NOT NULL DEFAULT 0,
    loot_6       INTEGER NOT NULL DEFAULT 0,
    loot_7       INTEGER NOT NULL DEFAULT 0,
    loot_8       INTEGER NOT NULL DEFAULT 0,
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

CREATE TABLE object_functions (
    obj_vnum     INTEGER PRIMARY KEY REFERENCES objects(vnum),
    func_name    TEXT    NOT NULL
);

-- ---------------------------------------------------------------------------
-- Help systems
-- ---------------------------------------------------------------------------

CREATE TABLE help_entries (
    id           SERIAL  PRIMARY KEY,
    filename     TEXT    NOT NULL UNIQUE,
    level        INTEGER NOT NULL,
    keywords     TEXT    NOT NULL,
    body         TEXT    NOT NULL
);

CREATE TABLE shelp_entries (
    id           SERIAL  PRIMARY KEY,
    filename     TEXT    NOT NULL UNIQUE,
    level        INTEGER NOT NULL,
    keywords     TEXT    NOT NULL,
    body         TEXT    NOT NULL
);

-- ---------------------------------------------------------------------------
-- Lore
-- ---------------------------------------------------------------------------

CREATE TABLE lore_topics (
    id           SERIAL PRIMARY KEY,
    filename     TEXT   NOT NULL UNIQUE,
    keywords     TEXT   NOT NULL
);

CREATE TABLE lore_entries (
    id           SERIAL  PRIMARY KEY,
    topic_id     INTEGER NOT NULL REFERENCES lore_topics(id),
    seq          INTEGER NOT NULL,
    flags        BIGINT  NOT NULL DEFAULT 0,
    body         TEXT    NOT NULL,
    UNIQUE(topic_id, seq)
);

-- ---------------------------------------------------------------------------
-- Runtime state (data/)
-- ---------------------------------------------------------------------------

CREATE TABLE bans (
    id           SERIAL  PRIMARY KEY,
    ban_type     INTEGER NOT NULL DEFAULT 0,
    address      TEXT    NOT NULL,
    banned_by    TEXT    NOT NULL DEFAULT ''
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

CREATE TABLE clans (
    id            INTEGER   PRIMARY KEY,
    name          TEXT      NOT NULL DEFAULT '',
    war_count     INTEGER   NOT NULL DEFAULT 0,
    win_count     INTEGER   NOT NULL DEFAULT 0,
    loss_count    INTEGER   NOT NULL DEFAULT 0,
    member_count  INTEGER   NOT NULL DEFAULT 0,
    gold          INTEGER   NOT NULL DEFAULT 0,
    war_matrix    INTEGER[] NOT NULL DEFAULT '{}'
);

CREATE TABLE rulers (
    id           SERIAL PRIMARY KEY,
    name         TEXT   NOT NULL UNIQUE
);

CREATE TABLE brands (
    id           SERIAL PRIMARY KEY,
    branded_by   TEXT   NOT NULL,
    item_name    TEXT   NOT NULL,
    brand_date   TEXT   NOT NULL,
    description  TEXT   NOT NULL DEFAULT ''
);

CREATE TABLE room_marks (
    id           SERIAL  PRIMARY KEY,
    room_vnum    INTEGER NOT NULL,
    mark_text    TEXT    NOT NULL
);

CREATE TABLE corpses (
    id           SERIAL  PRIMARY KEY,
    where_vnum   INTEGER NOT NULL,
    nest         INTEGER NOT NULL DEFAULT 0,
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
    timer        INTEGER NOT NULL DEFAULT 0,
    cost         INTEGER NOT NULL DEFAULT 0,
    value_0      INTEGER NOT NULL DEFAULT 0,
    value_1      INTEGER NOT NULL DEFAULT 0,
    value_2      INTEGER NOT NULL DEFAULT 0,
    value_3      INTEGER NOT NULL DEFAULT 0,
    parent_id    INTEGER REFERENCES corpses(id)
);

CREATE TABLE sysdata (
    id           INTEGER PRIMARY KEY DEFAULT 1 CHECK(id = 1),
    mud_name     TEXT    NOT NULL DEFAULT '',
    admin_email  TEXT    NOT NULL DEFAULT '',
    login_msg    TEXT    NOT NULL DEFAULT '',
    motd         TEXT    NOT NULL DEFAULT '',
    welcome      TEXT    NOT NULL DEFAULT '',
    news         TEXT    NOT NULL DEFAULT '',
    int_val_1    INTEGER NOT NULL DEFAULT 0,
    int_val_2    INTEGER NOT NULL DEFAULT 0,
    bln_val_0    INTEGER NOT NULL DEFAULT 0,
    bln_val_1    INTEGER NOT NULL DEFAULT 0,
    bln_val_2    INTEGER NOT NULL DEFAULT 0,
    bln_val_3    INTEGER NOT NULL DEFAULT 0,
    bln_val_4    INTEGER NOT NULL DEFAULT 0,
    bln_val_5    INTEGER NOT NULL DEFAULT 0,
    bln_val_6    INTEGER NOT NULL DEFAULT 0,
    bln_val_7    INTEGER NOT NULL DEFAULT 0
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
CREATE INDEX ON corpses(where_vnum);
CREATE INDEX ON corpses(parent_id);

-- Full-text keyword search for help/shelp/lore
CREATE INDEX ON help_entries  USING GIN (to_tsvector('english', keywords));
CREATE INDEX ON shelp_entries USING GIN (to_tsvector('english', keywords));
CREATE INDEX ON lore_topics   USING GIN (to_tsvector('english', keywords));

-- ---------------------------------------------------------------------------
-- Schema version
-- ---------------------------------------------------------------------------

CREATE TABLE schema_version (
    version    INTEGER                  NOT NULL,
    applied_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

INSERT INTO schema_version (version) VALUES (1);
