#!/bin/sh
# Reassign ownership of all tables and sequences in the acktng database
# to the ack role. Run as root or with sudo.
#
# This fixes "must be owner of table" errors when applying schema changes
# as the ack role on tables originally created by the postgres superuser.
#
# Usage: fix-table-ownership.sh [--db DATABASE] [--user ROLE]

set -e

PG_DB="${PG_DB:-acktng}"
PG_USER="${PG_USER:-ack}"

while [ $# -gt 0 ]; do
    case "$1" in
        --db)   PG_DB="$2";   shift 2 ;;
        --user) PG_USER="$2"; shift 2 ;;
        *)      echo "Unknown argument: $1" >&2; exit 1 ;;
    esac
done

echo "Reassigning ownership in '$PG_DB' to '$PG_USER'..."

sudo -u postgres psql -v ON_ERROR_STOP=1 -d "$PG_DB" <<SQL
DO \$\$
DECLARE r RECORD;
BEGIN
  FOR r IN SELECT tablename FROM pg_tables WHERE schemaname = 'public' LOOP
    EXECUTE 'ALTER TABLE public.' || quote_ident(r.tablename) || ' OWNER TO $PG_USER';
  END LOOP;
  FOR r IN SELECT sequence_name FROM information_schema.sequences WHERE sequence_schema = 'public' LOOP
    EXECUTE 'ALTER SEQUENCE public.' || quote_ident(r.sequence_name) || ' OWNER TO $PG_USER';
  END LOOP;
END
\$\$;
SQL

echo "Done. All tables and sequences in '$PG_DB' are now owned by '$PG_USER'."
