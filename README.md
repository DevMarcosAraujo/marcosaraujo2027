# Meu Site (marcosaraujo.dev.br)

Monorepo do portfólio.

- `apps/web`: Next.js (output standalone)
- `apps/api`: Node.js + Express + TypeScript
- PostgreSQL e Caddy (HTTPS automático) via Docker Compose
- `infra/`: Caddyfile e scripts (backup, restore, check-env)

## Rodar em desenvolvimento

```bash
# banco e Adminer (só em 127.0.0.1)
docker compose -f docker-compose.dev.yml up -d

# web
cd apps/web && npm ci && npm run dev      # http://localhost:3000

# api
cd apps/api && npm ci && DB_USER=dev DB_PASSWORD=dev DB_NAME=meusite_dev DB_HOST=127.0.0.1 npm run dev
```

Adminer: http://127.0.0.1:8080 (servidor `db`, usuário `dev`, senha `dev`). Credenciais só de dev.

## Primeiro deploy (VPS Ubuntu)

1. Instale Docker e o plugin Compose. Crie um usuário `deploy` sem sudo, no grupo `docker`, só com login por chave.
2. Libere no firewall apenas as portas 22, 80 e 443. O DNS de `DOMAIN` e `www.DOMAIN` deve apontar para a VPS.
3. Clone o repositório (ex.: `/opt/meu-site`) e entre na pasta.
4. Crie o `.env` a partir do exemplo e preencha:
   ```bash
   cp .env.example .env && chmod 600 .env
   ```
5. Gere os segredos (nunca no Git):
   ```bash
   mkdir -p secrets && chmod 700 secrets
   openssl rand -base64 48 > secrets/db_password.txt
   openssl rand -base64 48 > secrets/jwt_secret.txt
   chmod 600 secrets/*
   ```
6. Valide e suba:
   ```bash
   infra/scripts/check-env.sh
   docker compose up -d --build
   docker compose ps
   ```
7. Para o deploy automático, crie o environment `production` no GitHub com os secrets:
   `VPS_HOST`, `VPS_USER`, `VPS_PATH`, `VPS_SSH_KEY` (chave privada do usuário deploy) e
   `VPS_KNOWN_HOSTS` (saída de `ssh-keyscan -t ed25519 SEU_HOST`).

## Backup e restauração

```bash
infra/scripts/backup-db.sh                       # gera backups/db_*.sql.gz (retenção 14 dias)
infra/scripts/restore-db.sh backups/db_XXXX.sql.gz   # pede confirmação e sobrescreve o banco
```

Agende o backup no cron e copie os arquivos para fora da VPS. Veja o checklist em [SECURITY.md](SECURITY.md).
