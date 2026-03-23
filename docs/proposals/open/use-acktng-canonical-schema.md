# Use acktng's Canonical Schema in tngdb

## Problem

tngdb maintains its own copy of `area/schema.sql` and a set of migration files in `area/migrations/`. This duplicates acktng's canonical schema, requiring every schema change to be made in both repos. This has already caused drift and will continue to be a maintenance burden.

## Approach

Remove tngdb's own schema and point all scripts at acktng's canonical copy instead.

### 1. Remove tngdb's duplicate schema

- Delete `tngdb/area/schema.sql`
- Delete `tngdb/area/migrations/` and all migration files

### 2. Update `install-db-server.sh`

Change the `SCHEMA` variable to point to acktng's schema:

```sh
SCHEMA="$SCRIPT_DIR/../../acktng/area/schema.sql"
```

Add a check that the file exists, with a clear error message if acktng isn't cloned.

### 3. Update `migrate.sh`

Replace the migration-file approach with applying acktng's full `schema.sql`. Since acktng's schema uses `CREATE TABLE IF NOT EXISTS` throughout, it's idempotent — safe to re-apply on an existing database.

### 4. Simplify future workflow

Schema changes only need to happen in acktng. tngdb automatically picks them up.

## Affected Files

- `tngdb/area/schema.sql` — delete
- `tngdb/area/migrations/*` — delete
- `tngdb/scripts/install-db-server.sh` — update schema path
- `tngdb/scripts/migrate.sh` — apply acktng schema.sql instead of migration files

## Trade-offs

- **Hard dependency on acktng**: tngdb can no longer function standalone without acktng being cloned alongside it. This is acceptable because the aicli workspace already clones both, and tngdb is inherently coupled to acktng's database schema.
- **No incremental migrations**: Applying the full schema each time is slightly heavier than targeted migrations, but `CREATE TABLE IF NOT EXISTS` makes it effectively a no-op on an up-to-date database. For destructive changes (column renames, drops), manual migration scripts can still be added to acktng if needed.
