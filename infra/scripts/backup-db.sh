#!/usr/bin/env bash
# Backup do Postgres com retenção. Uso: infra/scripts/backup-db.sh
# Variáveis opcionais: BACKUP_DIR (padrão ./backups), RETENTION_DAYS (padrão 14)
# Agende no cron da VPS, por exemplo: 0 3 * * * cd /opt/meu-site && infra/scripts/backup-db.sh
set -euo pipefail

cd "$(dirname "$0")/../.."
BACKUP_DIR="${BACKUP_DIR:-./backups}"
RETENTION_DAYS="${RETENTION_DAYS:-14}"
set -a; . ./.env; set +a

mkdir -p "$BACKUP_DIR"
chmod 700 "$BACKUP_DIR"
arquivo="$BACKUP_DIR/db_$(date +%Y%m%d_%H%M%S).sql.gz"

docker compose exec -T db pg_dump -U "$POSTGRES_USER" -d "$POSTGRES_DB" --clean --if-exists \
  | gzip > "$arquivo.tmp"
mv "$arquivo.tmp" "$arquivo"
chmod 600 "$arquivo"
echo "Backup criado: $arquivo"

find "$BACKUP_DIR" -name 'db_*.sql.gz' -type f -mtime +"$RETENTION_DAYS" -print -delete
