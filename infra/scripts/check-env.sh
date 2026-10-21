#!/usr/bin/env bash
# Valida o .env e os arquivos de segredo antes de subir a stack.
# Uso: infra/scripts/check-env.sh [caminho-do-.env]
set -euo pipefail

ENV_FILE="${1:-.env}"
MIN_SECRET_LEN=32
REQUIRED_VARS=(DOMAIN ACME_EMAIL POSTGRES_USER POSTGRES_DB)
SECRET_FILES=(secrets/db_password.txt secrets/jwt_secret.txt)
erros=0

falha() { echo "ERRO: $1" >&2; erros=$((erros + 1)); }

[ -f "$ENV_FILE" ] || { echo "ERRO: $ENV_FILE não existe (copie de .env.example)" >&2; exit 1; }

for var in "${REQUIRED_VARS[@]}"; do
  valor="$(grep -E "^${var}=" "$ENV_FILE" | tail -n1 | cut -d= -f2- || true)"
  if [ -z "$valor" ]; then
    falha "variável $var ausente ou vazia em $ENV_FILE"
  elif [[ "$valor" == *exemplo* ]]; then
    falha "variável $var ainda tem valor de exemplo"
  fi
done

for arq in "${SECRET_FILES[@]}"; do
  if [ ! -f "$arq" ]; then
    falha "$arq não existe"
    continue
  fi
  tamanho="$(tr -d '\n\r' < "$arq" | wc -c)"
  if [ "$tamanho" -lt "$MIN_SECRET_LEN" ]; then
    falha "$arq tem $tamanho caracteres (mínimo $MIN_SECRET_LEN)"
  fi
  perm="$(stat -c '%a' "$arq")"
  if [ "$perm" != "600" ] && [ "$perm" != "400" ]; then
    falha "$arq com permissão $perm (use chmod 600)"
  fi
done

if [ "$erros" -gt 0 ]; then
  echo "Verificação falhou com $erros erro(s)." >&2
  exit 1
fi
echo "OK: .env e segredos válidos."
