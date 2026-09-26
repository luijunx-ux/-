#!/usr/bin/env sh
set -eu

if [ "$#" -ne 1 ]; then
  printf 'Usage: CONFIRM_RESTORE=RESTORE_TIANRENLU %s <backup.dump>\n' "$0" >&2
  exit 2
fi

if [ "${CONFIRM_RESTORE:-}" != "RESTORE_TIANRENLU" ]; then
  printf 'Restore refused: set CONFIRM_RESTORE=RESTORE_TIANRENLU after approval.\n' >&2
  exit 2
fi

BACKUP_FILE=$1
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
COMPOSE_FILE=${COMPOSE_FILE:-"$SCRIPT_DIR/../docker/docker-compose.prod.yml"}

test -f "$BACKUP_FILE"
if [ -f "$BACKUP_FILE.sha256" ]; then
  (cd "$(dirname -- "$BACKUP_FILE")" && sha256sum -c "$(basename -- "$BACKUP_FILE").sha256")
fi

docker compose -f "$COMPOSE_FILE" stop api
docker compose -f "$COMPOSE_FILE" exec -T postgres sh -c \
  'PGPASSWORD="$POSTGRES_PASSWORD" pg_restore --clean --if-exists --no-owner --no-privileges --username="$POSTGRES_USER" --dbname="$POSTGRES_DB"' \
  < "$BACKUP_FILE"
docker compose -f "$COMPOSE_FILE" run --rm migrate
docker compose -f "$COMPOSE_FILE" up -d api

printf 'Restore completed. Verify /health/ready and the Alpha smoke-test checklist.\n'
