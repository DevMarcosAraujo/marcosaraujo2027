# Segurança

Checklist de infraestrutura. Marque antes do primeiro deploy e revise a cada mudança relevante.

## Containers
- [x] Multi-stage build: imagem final sem ferramentas de build nem devDependencies
- [x] Imagens base com tag exata (`node:22.12.0-alpine3.21`, `postgres:16.6-alpine3.21`, `caddy:2.8.4-alpine`)
- [x] Processos rodando como `node` (web e api), nunca root
- [x] `npm ci` com lockfile; nenhum segredo em `ARG`/`ENV` na imagem
- [x] `HEALTHCHECK` em todos os serviços
- [x] `read_only`, `tmpfs` em `/tmp`, `no-new-privileges`, `cap_drop: [ALL]`
- [x] Limites de CPU e memória por serviço
- [x] Logs com rotação (10 MB x 3 arquivos)

## Rede
- [x] Só o Caddy publica portas (80, 443)
- [x] Rede `internal` (api + db) sem acesso à internet; db não toca na rede `edge`
- [x] HTTPS automático, HSTS, `X-Content-Type-Options`, `X-Frame-Options`, `Referrer-Policy`, `Permissions-Policy`; header `Server` removido
- [ ] Firewall da VPS (ufw): liberar apenas 22, 80 e 443
- [ ] SSH só por chave, `PasswordAuthentication no`, `PermitRootLogin no`
- [ ] (Opcional) Cloudflare na frente: ver comentário no `infra/caddy/Caddyfile`

## Segredos
- [x] `.env` e `secrets/` no `.gitignore`; só `.env.example` no Git
- [x] Senha do banco e `JWT_SECRET` via Docker secrets (arquivos em `secrets/`, `chmod 600`)
- [ ] Gerar segredos novos na VPS: `openssl rand -base64 48 > secrets/<nome>.txt`
- [ ] Rodar `infra/scripts/check-env.sh` antes de cada deploy (o workflow já faz)

## Pipeline
- [x] Gitleaks (vazamento de segredos), `npm audit` (HIGH+) e Trivy (HIGH/CRITICAL com correção) no CI
- [x] Deploy só depois do CI passar; SSH com host key fixada (`VPS_KNOWN_HOSTS`)
- [ ] Usuário de deploy na VPS sem sudo, só com acesso ao Docker e à pasta do projeto
- [ ] Proteger a branch `main` no GitHub (PR + CI obrigatório)

## Backup
- [ ] Cron diário: `infra/scripts/backup-db.sh` (retenção padrão 14 dias)
- [ ] Copiar backups para fora da VPS
- [ ] Testar a restauração (`infra/scripts/restore-db.sh`) ao menos uma vez

## Antes de publicar o painel admin
- [ ] Rodar `/security-audit` (OWASP Top 10:2025) no código
- [ ] Rate limit no login, cookie `httpOnly`/`secure`/`sameSite`, proteção CSRF

## Atenção
- O `db` usa `cap_add` (CHOWN, FOWNER, SETUID, SETGID, DAC_OVERRIDE) porque o entrypoint do Postgres precisa deles.
- A `api` está nas redes `edge` e `internal`, então tem saída para a internet.

## Reportar vulnerabilidade
Abra uma issue privada no repositório ou envie e-mail ao mantenedor.
