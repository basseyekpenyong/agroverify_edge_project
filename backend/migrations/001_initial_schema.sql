-- AgroVerify Edge — PostgreSQL Cloud Schema
-- Migration: 001_initial_schema

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TYPE sync_status AS ENUM ('pending', 'syncing', 'synced', 'failed');
CREATE TYPE user_role AS ENUM ('field_agent', 'cooperative_manager', 'admin', 'enterprise');

CREATE TABLE agents (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name          TEXT NOT NULL,
  pin_hash      TEXT NOT NULL,
  region        TEXT NOT NULL,
  cooperative_id TEXT NOT NULL,
  role          user_role NOT NULL DEFAULT 'field_agent',
  active        BOOLEAN NOT NULL DEFAULT TRUE,
  last_active   TIMESTAMPTZ,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE transactions (
  id              UUID PRIMARY KEY,
  commodity_type  TEXT NOT NULL,
  weight          NUMERIC(12, 3) NOT NULL,
  unit            TEXT NOT NULL,
  buyer_id        TEXT NOT NULL,
  seller_id       TEXT NOT NULL,
  gps_lat         NUMERIC(10, 6) NOT NULL,
  gps_lng         NUMERIC(10, 6) NOT NULL,
  gps_accuracy    NUMERIC(8, 2),
  timestamp_utc   TIMESTAMPTZ NOT NULL,
  integrity_hash  TEXT NOT NULL,
  sync_status     sync_status NOT NULL DEFAULT 'synced',
  agent_id        UUID NOT NULL REFERENCES agents(id),
  notes           TEXT,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  synced_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE integrity_alerts (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  transaction_id  UUID NOT NULL,
  agent_id        UUID NOT NULL REFERENCES agents(id),
  expected_hash   TEXT NOT NULL,
  received_hash   TEXT NOT NULL,
  resolved        BOOLEAN NOT NULL DEFAULT FALSE,
  flagged_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE erp_webhooks (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id   TEXT NOT NULL,
  url         TEXT NOT NULL,
  secret      TEXT NOT NULL,
  active      BOOLEAN NOT NULL DEFAULT TRUE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE model_manifests (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  model_type  TEXT NOT NULL CHECK(model_type IN ('voice', 'vision')),
  version     TEXT NOT NULL,
  url         TEXT NOT NULL,
  checksum    TEXT NOT NULL,
  active      BOOLEAN NOT NULL DEFAULT TRUE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_transactions_agent ON transactions(agent_id);
CREATE INDEX idx_transactions_timestamp ON transactions(timestamp_utc DESC);
CREATE INDEX idx_transactions_sync_status ON transactions(sync_status);
CREATE INDEX idx_alerts_resolved ON integrity_alerts(resolved) WHERE resolved = FALSE;
