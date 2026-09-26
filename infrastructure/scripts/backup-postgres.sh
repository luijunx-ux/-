#!/usr/bin/env sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
COMPOSE_FILE=${COMPOSE_FILE:-"$SCRIPT_DIR/../docker/docker-compose.prod.yml"}
BACKUP_DIR=${BACKUP_DIR:-"$SCRIPT_DIR/../backups"}
TIMESTAMP=$(date -u +%Y%m%dT%H%M%SZ)
BACKUP_FILE="$BACKUP_DIR/tianrenlu-$TIMESTAMP.dump"

mkdir -p "$BACKUP_DIR"
umask 077

docker compose -f "$COMPOSE_FILE" exec -T postgres sh -c \
  'PGPASSWORD="$POSTGRES_PASSWORD" pg_dump --format=custom --no-owner --no-privileges --username="$POSTGRES_USER" --dbname="$POSTGRES_DB"' \
  > "$BACKUP_FILE"

test -s "$BACKUP_FILE"
(cd "$BACKUP_DIR" && sha256sum "$(basename -- "$BACKUP_FILE")" > "$(basename -- "$BACKUP_FILE").sha256")
printf 'Backup created: %s\n' "$BACKUP_FILE"
