#!/bin/sh
# Install PostgreSQL server packages on a Debian host.
# Run as root (or via sudo).

set -e

apt-get update
apt-get install -y postgresql postgresql-client
