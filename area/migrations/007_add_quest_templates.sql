-- Migration 007: Add quest_templates table
-- Stores quest template data imported from acktng quests/*.prop files.

BEGIN;

CREATE TABLE IF NOT EXISTS quest_templates (
    id                       INTEGER PRIMARY KEY,
    title                    TEXT    NOT NULL,
    prerequisite_template_id INTEGER,
    type                     INTEGER NOT NULL DEFAULT 0,
    num_targets              INTEGER NOT NULL DEFAULT 0,
    target_vnums             INTEGER[] NOT NULL DEFAULT '{}',
    kill_needed              INTEGER NOT NULL DEFAULT 0,
    min_level                INTEGER NOT NULL DEFAULT 0,
    max_level                INTEGER NOT NULL DEFAULT 170,
    offerer_vnum             INTEGER,
    reward_gold              INTEGER NOT NULL DEFAULT 0,
    reward_qp                INTEGER NOT NULL DEFAULT 0,
    reward_exp               INTEGER NOT NULL DEFAULT 0,
    accept_message           TEXT    NOT NULL DEFAULT '',
    completion_message       TEXT    NOT NULL DEFAULT '',
    reward_obj_short         TEXT    NOT NULL DEFAULT '',
    reward_obj_name          TEXT    NOT NULL DEFAULT '',
    reward_obj_long          TEXT    NOT NULL DEFAULT '',
    reward_obj_wear_flags    INTEGER NOT NULL DEFAULT 0,
    reward_obj_extra_flags   INTEGER NOT NULL DEFAULT 0,
    reward_obj_weight        INTEGER NOT NULL DEFAULT 0,
    reward_obj_item_apply    INTEGER NOT NULL DEFAULT 0
);

INSERT INTO schema_version (version, description)
    VALUES (7, 'Add quest_templates table');

COMMIT;
