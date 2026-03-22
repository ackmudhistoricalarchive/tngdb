-- Migration 003: stored tsvector columns for full-text search
--
-- Replaces the expression-based GIN indexes on help_entries, shelp_entries,
-- and lore_topics with stored generated tsvector columns that cover multiple
-- fields at different weights:
--
--   A (highest) — keyword   : the game's own keyword tags
--   B           — title/name: human-readable title
--   C (lowest)  — text/desc : full body text
--
-- Benefits over the previous approach:
--   * The GIN index is on a real column so planner always hits it.
--   * ts_rank() can be used directly in ORDER BY for relevance sorting.
--   * Searching title and body text finds entries the old index would miss.
--
-- Apply with:
--   psql -U ack -d acktng -f area/migrations/003_tsvector_search.sql

BEGIN;

-- ---------------------------------------------------------------------------
-- help_entries
-- ---------------------------------------------------------------------------

DROP INDEX IF EXISTS help_entries_to_tsvector_idx;

ALTER TABLE help_entries
    ADD COLUMN textsearch tsvector
        GENERATED ALWAYS AS (
              setweight(to_tsvector('english', coalesce(keyword, '')), 'A')
           || setweight(to_tsvector('english', coalesce(title,   '')), 'B')
           || setweight(to_tsvector('english', coalesce(text,    '')), 'C')
        ) STORED;

CREATE INDEX help_entries_textsearch_idx ON help_entries USING GIN (textsearch);

-- ---------------------------------------------------------------------------
-- shelp_entries
-- ---------------------------------------------------------------------------

DROP INDEX IF EXISTS shelp_entries_to_tsvector_idx;

ALTER TABLE shelp_entries
    ADD COLUMN textsearch tsvector
        GENERATED ALWAYS AS (
              setweight(to_tsvector('english', coalesce(keyword, '')), 'A')
           || setweight(to_tsvector('english', coalesce(title,   '')), 'B')
           || setweight(to_tsvector('english', coalesce(text,    '')), 'C')
        ) STORED;

CREATE INDEX shelp_entries_textsearch_idx ON shelp_entries USING GIN (textsearch);

-- ---------------------------------------------------------------------------
-- lore_topics
-- ---------------------------------------------------------------------------

DROP INDEX IF EXISTS lore_topics_to_tsvector_idx;

ALTER TABLE lore_topics
    ADD COLUMN textsearch tsvector
        GENERATED ALWAYS AS (
              setweight(to_tsvector('english', coalesce(keyword,     '')), 'A')
           || setweight(to_tsvector('english', coalesce(name,        '')), 'B')
           || setweight(to_tsvector('english', coalesce(description, '')), 'C')
        ) STORED;

CREATE INDEX lore_topics_textsearch_idx ON lore_topics USING GIN (textsearch);

-- ---------------------------------------------------------------------------
-- Schema version
-- ---------------------------------------------------------------------------

INSERT INTO schema_version (version, description)
    VALUES (3, 'Add stored tsvector columns for weighted full-text search');

COMMIT;
