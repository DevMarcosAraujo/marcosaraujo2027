#!/usr/bin/env bash
# Restaura um backup. Uso: infra/scripts/restore-db.sh backups/db_AAAAMMDD_HHMMSS.sql.gz
# ATENÇÃO: sobrescreve os dados atuais do banco.
set -euo pipefail

[ $# -eq 1 ] && [ -f "$1" ] || { echo "Uso: $0 <arquivo.sql.gz>" >&2; exit 1; }
cd "$(dirname "$0")/../.."
set -a; . ./.env; set +a

read -r -p "Isso vai sobrescrever o banco '$POSTGRES_DB'. Digite 'sim' para continuar: " resp
[ "$resp" = "sim" ] || { echo "Cancelado."; exit 1; }

gunzip -c "$1" | docker compose exec -T db psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -v ON_ERROR_STOP=1
echo "Restauração concluída."
