# Use acktng's Canonical Schema in tngdb

## Problem

tngdb maintained its own copy of `area/schema.sql` and migration files. This duplicated acktng's canonical schema, requiring every schema change to be made in both repos.

## Approach

Remove tngdb's duplicate schema and point all scripts at acktng's canonical `area/schema.sql`. Since acktng's schema uses `CREATE TABLE IF NOT EXISTS` throughout, it's idempotent and safe to re-apply.

## Trade-offs

- tngdb requires acktng to be cloned alongside it (already the case in aicli workspace)
- No incremental migrations — full schema is re-applied each time (effectively a no-op on up-to-date databases)
