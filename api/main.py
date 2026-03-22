"""
ACK!TNG database API server.

Exposes read-only endpoints for lores, helps, and shelps so the web server
can query the PostgreSQL database without a direct DB connection.

Environment variable required:
    DATABASE_URL  – asyncpg-compatible connection string, e.g.
                    postgres://ack:password@localhost/acktng
"""

import os

import asyncpg
from fastapi import FastAPI, HTTPException, Query
from pydantic import BaseModel

app = FastAPI(title="ACK!TNG DB API")

pool: asyncpg.Pool | None = None


# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------


@app.on_event("startup")
async def startup() -> None:
    global pool
    pool = await asyncpg.create_pool(os.environ["DATABASE_URL"])


@app.on_event("shutdown")
async def shutdown() -> None:
    if pool:
        await pool.close()


# ---------------------------------------------------------------------------
# Response models
# ---------------------------------------------------------------------------


class HelpEntry(BaseModel):
    id: int
    filename: str
    level: int
    keywords: str
    body: str


class SHelpEntry(BaseModel):
    id: int
    filename: str
    level: int
    keywords: str
    body: str


class LoreEntry(BaseModel):
    id: int
    seq: int
    flags: int
    body: str


class LoreTopic(BaseModel):
    id: int
    filename: str
    keywords: str
    entries: list[LoreEntry]


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


def _require_pool() -> asyncpg.Pool:
    if pool is None:
        raise HTTPException(status_code=503, detail="Database not available")
    return pool


# ---------------------------------------------------------------------------
# Helps  (/helps)
# ---------------------------------------------------------------------------


@app.get("/helps", response_model=list[HelpEntry])
async def list_helps(
    keyword: str | None = Query(None, description="Search keyword (full-text)"),
    level: int | None = Query(None, description="Maximum level required"),
):
    """
    Return all help entries, optionally filtered by keyword and/or level.

    When *keyword* is supplied the GIN full-text index is used so that
    `?keyword=fire` matches entries whose keywords field contains the word
    "fire" (English stemming applies).
    """
    db = _require_pool()

    if keyword:
        rows = await db.fetch(
            """
            SELECT id, filename, level, keywords, body
            FROM help_entries
            WHERE to_tsvector('english', keywords)
                  @@ plainto_tsquery('english', $1)
            ORDER BY level, id
            """,
            keyword,
        )
    else:
        rows = await db.fetch(
            "SELECT id, filename, level, keywords, body FROM help_entries ORDER BY level, id"
        )

    entries = [HelpEntry(**dict(r)) for r in rows]
    if level is not None:
        entries = [e for e in entries if e.level <= level]
    return entries


@app.get("/helps/{entry_id}", response_model=HelpEntry)
async def get_help(entry_id: int):
    """Return a single help entry by ID."""
    db = _require_pool()
    row = await db.fetchrow(
        "SELECT id, filename, level, keywords, body FROM help_entries WHERE id = $1",
        entry_id,
    )
    if row is None:
        raise HTTPException(status_code=404, detail="Help entry not found")
    return HelpEntry(**dict(row))


# ---------------------------------------------------------------------------
# SHelps  (/shelps)
# ---------------------------------------------------------------------------


@app.get("/shelps", response_model=list[SHelpEntry])
async def list_shelps(
    keyword: str | None = Query(None, description="Search keyword (full-text)"),
    level: int | None = Query(None, description="Maximum level required"),
):
    """
    Return all skill-help entries, optionally filtered by keyword and/or level.
    """
    db = _require_pool()

    if keyword:
        rows = await db.fetch(
            """
            SELECT id, filename, level, keywords, body
            FROM shelp_entries
            WHERE to_tsvector('english', keywords)
                  @@ plainto_tsquery('english', $1)
            ORDER BY level, id
            """,
            keyword,
        )
    else:
        rows = await db.fetch(
            "SELECT id, filename, level, keywords, body FROM shelp_entries ORDER BY level, id"
        )

    entries = [SHelpEntry(**dict(r)) for r in rows]
    if level is not None:
        entries = [e for e in entries if e.level <= level]
    return entries


@app.get("/shelps/{entry_id}", response_model=SHelpEntry)
async def get_shelp(entry_id: int):
    """Return a single skill-help entry by ID."""
    db = _require_pool()
    row = await db.fetchrow(
        "SELECT id, filename, level, keywords, body FROM shelp_entries WHERE id = $1",
        entry_id,
    )
    if row is None:
        raise HTTPException(status_code=404, detail="SHelp entry not found")
    return SHelpEntry(**dict(row))


# ---------------------------------------------------------------------------
# Lores  (/lores)
# ---------------------------------------------------------------------------


@app.get("/lores", response_model=list[LoreTopic])
async def list_lores(
    keyword: str | None = Query(None, description="Search keyword (full-text)"),
):
    """
    Return all lore topics (with their ordered entries), optionally filtered
    by keyword.
    """
    db = _require_pool()

    if keyword:
        topic_rows = await db.fetch(
            """
            SELECT id, filename, keywords
            FROM lore_topics
            WHERE to_tsvector('english', keywords)
                  @@ plainto_tsquery('english', $1)
            ORDER BY id
            """,
            keyword,
        )
    else:
        topic_rows = await db.fetch(
            "SELECT id, filename, keywords FROM lore_topics ORDER BY id"
        )

    if not topic_rows:
        return []

    topic_ids = [r["id"] for r in topic_rows]
    entry_rows = await db.fetch(
        """
        SELECT id, topic_id, seq, flags, body
        FROM lore_entries
        WHERE topic_id = ANY($1::int[])
        ORDER BY topic_id, seq
        """,
        topic_ids,
    )

    # Group entries by topic_id
    entries_by_topic: dict[int, list[LoreEntry]] = {tid: [] for tid in topic_ids}
    for r in entry_rows:
        entries_by_topic[r["topic_id"]].append(
            LoreEntry(id=r["id"], seq=r["seq"], flags=r["flags"], body=r["body"])
        )

    return [
        LoreTopic(
            id=r["id"],
            filename=r["filename"],
            keywords=r["keywords"],
            entries=entries_by_topic[r["id"]],
        )
        for r in topic_rows
    ]


@app.get("/lores/{topic_id}", response_model=LoreTopic)
async def get_lore(topic_id: int):
    """Return a single lore topic with all its ordered entries."""
    db = _require_pool()

    row = await db.fetchrow(
        "SELECT id, filename, keywords FROM lore_topics WHERE id = $1",
        topic_id,
    )
    if row is None:
        raise HTTPException(status_code=404, detail="Lore topic not found")

    entry_rows = await db.fetch(
        """
        SELECT id, seq, flags, body
        FROM lore_entries
        WHERE topic_id = $1
        ORDER BY seq
        """,
        topic_id,
    )

    return LoreTopic(
        id=row["id"],
        filename=row["filename"],
        keywords=row["keywords"],
        entries=[LoreEntry(**dict(r)) for r in entry_rows],
    )
