'use strict';

const express = require('express');
const { Pool } = require('pg');

const app = express();

/**
 * ---- Config helpers ----
 */
const toInt = (v, fallback) => {
  const n = parseInt(v, 10);
  return Number.isFinite(n) ? n : fallback;
};

const requireEnv = (name) => {
  const v = process.env[name];
  return (v && String(v).trim().length > 0) ? v : null;
};

/**
 * ---- App metadata ----
 */
const startedAt = new Date();
const serviceName = process.env.SERVICE_NAME || 'azure-3-tier-api';

/**
 * ---- DB config ----
 * Important: do NOT throw during startup if env is missing.
 * Keep the service up (health check OK), but mark DB as unhealthy.
 */
const dbConfig = {
  user: requireEnv('DBUSER'),
  database: requireEnv('DB'),
  password: requireEnv('DBPASS'),
  host: requireEnv('DBHOST'),
  port: toInt(process.env.DBPORT, 5432),

  // Sensible connection behavior in App Service
  connectionTimeoutMillis: toInt(process.env.PG_CONN_TIMEOUT_MS, 5000),
  idleTimeoutMillis: toInt(process.env.PG_IDLE_TIMEOUT_MS, 30000),
  max: toInt(process.env.PG_POOL_MAX, 10),

  // Azure Postgres typically requires TLS; this matches your current approach
  ssl: { rejectUnauthorized: false }
};

const dbEnabled =
  !!dbConfig.user && !!dbConfig.database && !!dbConfig.password && !!dbConfig.host;

let pool = null;
if (dbEnabled) {
  pool = new Pool(dbConfig);

  // Never crash the process on pool-level errors
  pool.on('error', (err) => {
    console.error('[DB][pool error]', err);
  });
} else {
  console.warn('[DB] Disabled because one or more DB env vars are missing:', {
    DBUSER: !!dbConfig.user,
    DB: !!dbConfig.database,
    DBPASS: !!dbConfig.password,
    DBHOST: !!dbConfig.host,
    DBPORT: dbConfig.port
  });
}

/**
 * ---- Basic middleware ----
 */
app.disable('x-powered-by');

/**
 * ---- Health endpoints (no DB dependency) ----
 * Azure startup probe should hit something fast and reliable.
 */
app.get('/health', (req, res) => {
  res.status(200).json({
    ok: true,
    service: serviceName,
    uptimeSeconds: Math.floor((Date.now() - startedAt.getTime()) / 1000)
  });
});

/**
 * ---- DB health (optional) ----
 */
app.get('/health/db', async (req, res) => {
  if (!pool) {
    return res.status(503).json({
      ok: false,
      error: 'db_not_configured'
    });
  }

  try {
    const r = await pool.query('SELECT 1 AS ok');
    res.status(200).json({ ok: true, result: r.rows[0] });
  } catch (err) {
    console.error('[DB] health check failed', {
      code: err.code,
      message: err.message,
      host: dbConfig.host
    });
    res.status(503).json({
      ok: false,
      error: 'db_unhealthy',
      detail: err.code || err.message
    });
  }
});

/**
 * ---- Existing status endpoint ----
 * Keep behavior: returns 500 if DB query fails.
 */
app.get('/api/status', async (req, res) => {
  if (!pool) {
    return res.status(500).json({ error: 'db_not_configured' });
  }

  try {
    const result = await pool.query('SELECT now() as time');
    res.status(200).json(result.rows);
  } catch (err) {
    // Log only useful bits (avoid dumping secrets)
    console.error('[DB] query failed', {
      code: err.code,
      message: err.message,
      syscall: err.syscall,
      hostname: err.hostname
    });
    res.status(500).json({ error: 'db_query_failed' });
  }
});

/**
 * ---- 404 ----
 */
app.use((req, res) => {
  res.status(404).json({ message: 'Not Found' });
});

/**
 * ---- Error handler ----
 */
app.use((err, req, res, next) => {
  console.error('[APP] unhandled error', err);
  res.status(err.status || 500).json({
    message: 'Internal Server Error'
  });
});

module.exports = app;
