"""
Read-only HTTP API for ACK!TNG game content (helps, shelps, lores).

Configuration:
    DATABASE_URL  asyncpg-compatible DSN, e.g.
                  postgres://ack:password@localhost/acktng

Run:
    uvicorn api.main:app [--host 0.0.0.0 --port 8000]
"""

import asyncio
import logging
import os
from contextlib import asynccontextmanager
from typing import List, Optional

import asyncpg
from fastapi import FastAPI, HTTPException, Query

logger = logging.getLogger(__name__)
from pydantic import BaseModel


# ---------------------------------------------------------------------------
# Database connection pool
# ---------------------------------------------------------------------------

_pool: asyncpg.Pool | None = None


def _database_url() -> str:
    url = os.environ.get("DATABASE_URL", "")
    if not url:
        raise RuntimeError("DATABASE_URL environment variable is not set")
    return url


@asynccontextmanager
async def lifespan(app: FastAPI):
    global _pool
    url = _database_url()
    delay = 1
    for attempt in range(10):
        try:
            _pool = await asyncpg.create_pool(url)
            break
        except Exception as exc:
            if attempt == 9:
                raise
            logger.warning(
                "Database not ready (attempt %d/10): %s — retrying in %ds",
                attempt + 1, exc, delay,
            )
            await asyncio.sleep(delay)
            delay = min(delay * 2, 30)
    yield
    await _pool.close()


app = FastAPI(
    title="ACK!TNG DB API",
    description="Read-only API for game helps, skill-helps, lores, and skills.",
    version="1.0.0",
    lifespan=lifespan,
)


def pool() -> asyncpg.Pool:
    if _pool is None:
        raise RuntimeError("Database pool is not initialised")
    return _pool


# ---------------------------------------------------------------------------
# Response models
# ---------------------------------------------------------------------------

class HelpEntry(BaseModel):
    id: int
    keyword: str
    title: str
    level: int
    text: str


class SkillSummary(BaseModel):
    sn: int
    name: str
    has_script: bool


class SkillDetail(BaseModel):
    sn: int
    name: str
    has_script: bool
    script_source: Optional[str]


class LoreEntryItem(BaseModel):
    id: int
    seq: int
    keyword: str
    text: str


class LoreTopic(BaseModel):
    id: int
    name: str
    keyword: str
    description: str
    entries: List[LoreEntryItem]


# ---------------------------------------------------------------------------
# Helps
# ---------------------------------------------------------------------------

@app.get("/helps", response_model=List[HelpEntry], tags=["helps"])
async def list_helps(
    keyword: Optional[str] = Query(None, description="Full-text keyword search"),
    level: Optional[int] = Query(None, description="Restrict to entries with level ≤ n"),
):
    """List all help entries, with optional keyword and level filters.

    When *keyword* is supplied results are ordered by relevance (ts_rank),
    with matches in the keyword tag ranked above title and body-text matches.
    """
    conditions = []
    params: list = []
    order = "id"

    if keyword:
        params.append(keyword)
        n = len(params)
        conditions.append(f"textsearch @@ plainto_tsquery('english', ${n})")
        order = f"ts_rank(textsearch, plainto_tsquery('english', ${n})) DESC, id"
    if level is not None:
        params.append(level)
        conditions.append(f"level <= ${len(params)}")

    where = ("WHERE " + " AND ".join(conditions)) if conditions else ""
    sql = f"SELECT id, keyword, title, level, text FROM help_entries {where} ORDER BY {order}"

    async with pool().acquire() as conn:
        rows = await conn.fetch(sql, *params)
    return [dict(r) for r in rows]


@app.get("/helps/{entry_id}", response_model=HelpEntry, tags=["helps"])
async def get_help(entry_id: int):
    """Fetch a single help entry by ID."""
    async with pool().acquire() as conn:
        row = await conn.fetchrow(
            "SELECT id, keyword, title, level, text FROM help_entries WHERE id = $1",
            entry_id,
        )
    if row is None:
        raise HTTPException(status_code=404, detail="Help entry not found")
    return dict(row)


# ---------------------------------------------------------------------------
# SHelps
# ---------------------------------------------------------------------------

@app.get("/shelps", response_model=List[HelpEntry], tags=["shelps"])
async def list_shelps(
    keyword: Optional[str] = Query(None, description="Full-text keyword search"),
    level: Optional[int] = Query(None, description="Restrict to entries with level ≤ n"),
):
    """List all skill-help entries, with optional keyword and level filters.

    When *keyword* is supplied results are ordered by relevance (ts_rank),
    with matches in the keyword tag ranked above title and body-text matches.
    """
    conditions = []
    params: list = []
    order = "id"

    if keyword:
        params.append(keyword)
        n = len(params)
        conditions.append(f"textsearch @@ plainto_tsquery('english', ${n})")
        order = f"ts_rank(textsearch, plainto_tsquery('english', ${n})) DESC, id"
    if level is not None:
        params.append(level)
        conditions.append(f"level <= ${len(params)}")

    where = ("WHERE " + " AND ".join(conditions)) if conditions else ""
    sql = f"SELECT id, keyword, title, level, text FROM shelp_entries {where} ORDER BY {order}"

    async with pool().acquire() as conn:
        rows = await conn.fetch(sql, *params)
    return [dict(r) for r in rows]


@app.get("/shelps/{entry_id}", response_model=HelpEntry, tags=["shelps"])
async def get_shelp(entry_id: int):
    """Fetch a single skill-help entry by ID."""
    async with pool().acquire() as conn:
        row = await conn.fetchrow(
            "SELECT id, keyword, title, level, text FROM shelp_entries WHERE id = $1",
            entry_id,
        )
    if row is None:
        raise HTTPException(status_code=404, detail="SHelp entry not found")
    return dict(row)


# ---------------------------------------------------------------------------
# Lores
# ---------------------------------------------------------------------------

async def _fetch_lore_topic(conn: asyncpg.Connection, topic_id: int) -> dict | None:
    topic = await conn.fetchrow(
        "SELECT id, name, keyword, description FROM lore_topics WHERE id = $1",
        topic_id,
    )
    if topic is None:
        return None
    entries = await conn.fetch(
        "SELECT id, seq, keyword, text FROM lore_entries WHERE topic_id = $1 ORDER BY seq",
        topic_id,
    )
    return {**dict(topic), "entries": [dict(e) for e in entries]}


@app.get("/lores", response_model=List[LoreTopic], tags=["lores"])
async def list_lores(
    keyword: Optional[str] = Query(None, description="Full-text keyword search"),
):
    """List all lore topics (each with nested entries), with optional keyword filter.

    When *keyword* is supplied results are ordered by relevance (ts_rank),
    with matches in keyword tags ranked above name and description matches.
    """
    if keyword:
        sql = (
            "SELECT id FROM lore_topics "
            "WHERE textsearch @@ plainto_tsquery('english', $1) "
            "ORDER BY ts_rank(textsearch, plainto_tsquery('english', $1)) DESC, id"
        )
        params = [keyword]
    else:
        sql = "SELECT id FROM lore_topics ORDER BY id"
        params = []

    async with pool().acquire() as conn:
        topic_ids = [r["id"] for r in await conn.fetch(sql, *params)]
        results = []
        for tid in topic_ids:
            topic = await _fetch_lore_topic(conn, tid)
            if topic:
                results.append(topic)
    return results


@app.get("/lores/{topic_id}", response_model=LoreTopic, tags=["lores"])
async def get_lore(topic_id: int):
    """Fetch a single lore topic with all its body entries in seq order."""
    async with pool().acquire() as conn:
        topic = await _fetch_lore_topic(conn, topic_id)
    if topic is None:
        raise HTTPException(status_code=404, detail="Lore topic not found")
    return topic


# ---------------------------------------------------------------------------
# Skills
# ---------------------------------------------------------------------------

@app.get("/skills", response_model=List[SkillSummary], tags=["skills"])
async def list_skills(
    scripted: Optional[bool] = Query(None, description="Filter to only scripted (true) or unscripted (false) skills"),
    name: Optional[str] = Query(None, description="Case-insensitive substring match on name"),
):
    """List all skills and spells ordered by sn.

    *scripted=true* returns only entries that have a Lua script_source set.
    *scripted=false* returns only entries without a script (dispatched via C).
    *name* filters by case-insensitive substring match.
    """
    conditions = []
    params: list = []

    if scripted is True:
        conditions.append("script_source IS NOT NULL AND script_source <> ''")
    elif scripted is False:
        conditions.append("(script_source IS NULL OR script_source = '')")

    if name is not None:
        params.append(f"%{name}%")
        conditions.append(f"name ILIKE ${len(params)}")

    where = ("WHERE " + " AND ".join(conditions)) if conditions else ""
    sql = f"SELECT sn, name, (script_source IS NOT NULL AND script_source <> '') AS has_script FROM skills {where} ORDER BY sn"

    async with pool().acquire() as conn:
        rows = await conn.fetch(sql, *params)
    return [dict(r) for r in rows]


@app.get("/skills/{sn}", response_model=SkillDetail, tags=["skills"])
async def get_skill(sn: int):
    """Fetch a single skill or spell by its sn (skill number).

    Returns the full *script_source* if a Lua script is set.
    """
    async with pool().acquire() as conn:
        row = await conn.fetchrow(
            "SELECT sn, name, (script_source IS NOT NULL AND script_source <> '') AS has_script, script_source FROM skills WHERE sn = $1",
            sn,
        )
    if row is None:
        raise HTTPException(status_code=404, detail="Skill not found")
    return dict(row)
