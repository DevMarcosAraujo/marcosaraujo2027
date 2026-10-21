import { readFileSync } from "node:fs";
import express from "express";
import pg from "pg";

// Segredos vêm de arquivo (Docker secrets) em produção ou de variável em dev.
function secret(name: string): string | undefined {
  const file = process.env[`${name}_FILE`];
  if (file) return readFileSync(file, "utf8").trim();
  return process.env[name];
}

const pool = new pg.Pool({
  host: process.env.DB_HOST ?? "db",
  port: Number(process.env.DB_PORT ?? 5432),
  user: process.env.DB_USER,
  database: process.env.DB_NAME,
  password: secret("DB_PASSWORD"),
  max: 5,
});

const app = express();
app.disable("x-powered-by");

app.get("/health", (_req, res) => {
  res.json({ status: "ok" });
});

app.get("/api/health", async (_req, res) => {
  try {
    await pool.query("SELECT 1");
    res.json({ status: "ok", db: "ok" });
  } catch {
    res.status(503).json({ status: "error" });
  }
});

const port = Number(process.env.PORT ?? 4000);
app.listen(port, "0.0.0.0", () => {
  console.log(`api ouvindo na porta ${port}`);
});
