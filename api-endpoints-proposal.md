# Proposal: Web API Endpoints for Helps, SHelps, and Lores

## Overview

Once the database migration is complete, a lightweight read-only HTTP API server should be added so the web front-end can query game content (helps, skill-helps, and lores) from the PostgreSQL database without requiring a direct database connection.

## Proposed Tech Stack

- **Framework:** Python + FastAPI
- **Database driver:** asyncpg (async PostgreSQL)
- **Server:** uvicorn

**Dependencies** (`api/requirements.txt`):
```
fastapi>=0.100.0
uvicorn[standard]>=0.23.0
asyncpg>=0.28.0
```

**Configuration:** A single `DATABASE_URL` environment variable (e.g. `postgres://ack:password@localhost/acktng`).

---

## Proposed Endpoints

All endpoints are **read-only**.

### Helps — `help_entries` table

| Method | Path | Query params | Description |
|---|---|---|---|
| GET | `/helps` | `?keyword=`, `?level=` | List all help entries. When `keyword` is supplied, full-text search is used against the GIN index on `help_entries.keywords`. The optional `level` param restricts results to entries with level ≤ n. |
| GET | `/helps/{id}` | — | Fetch a single help entry by ID. |

**Response shape per entry:**
```json
{
  "id": 1,
  "filename": "fire",
  "level": 0,
  "keywords": "fire burn flame",
  "body": "..."
}
```

---

### SHelps — `shelp_entries` table

| Method | Path | Query params | Description |
|---|---|---|---|
| GET | `/shelps` | `?keyword=`, `?level=` | Same as `/helps` but against `shelp_entries`. |
| GET | `/shelps/{id}` | — | Fetch a single skill-help entry by ID. |

**Response shape per entry:** identical to helps.

---

### Lores — `lore_topics` + `lore_entries` tables

| Method | Path | Query params | Description |
|---|---|---|---|
| GET | `/lores` | `?keyword=` | List all lore topics, each with their ordered body entries nested inside. Full-text keyword search uses the GIN index on `lore_topics.keywords`. |
| GET | `/lores/{id}` | — | Fetch a single lore topic with all its body entries in `seq` order. |

**Response shape per topic:**
```json
{
  "id": 1,
  "filename": "dragon",
  "keywords": "dragon dragons",
  "entries": [
    { "id": 10, "seq": 1, "flags": 0, "body": "..." },
    { "id": 11, "seq": 2, "flags": 0, "body": "..." }
  ]
}
```

---

## Keyword Search

The schema already has GIN indexes for full-text search on all three content types:

```sql
CREATE INDEX ON help_entries  USING GIN (to_tsvector('english', keywords));
CREATE INDEX ON shelp_entries USING GIN (to_tsvector('english', keywords));
CREATE INDEX ON lore_topics   USING GIN (to_tsvector('english', keywords));
```

Searches will use `plainto_tsquery('english', $1)` — plain English stemming, no special syntax required from the caller.

---

## Running the Server

```bash
pip install -r api/requirements.txt
DATABASE_URL=postgres://ack:password@localhost/acktng uvicorn api.main:app
```

FastAPI auto-generates interactive docs at `/docs` once the server is running.

---

## Notes

- No writes to the database — all endpoints are `SELECT` only.
- The server uses an `asyncpg` connection pool, created at startup and torn down at shutdown.
- No schema changes are required; this builds entirely on the existing tables and indexes.
- Implementation follows after the database migration is confirmed complete.
