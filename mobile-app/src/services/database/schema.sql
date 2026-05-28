-- AgroVerify Edge — Local SQLite Schema (AES-256 encrypted via SQLCipher)

CREATE TABLE IF NOT EXISTS agents (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  pin_hash TEXT NOT NULL,
  region TEXT NOT NULL,
  cooperative_id TEXT NOT NULL,
  role TEXT NOT NULL CHECK(role IN ('field_agent', 'cooperative_manager', 'admin', 'enterprise')),
  last_active TEXT,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS transactions (
  id TEXT PRIMARY KEY,
  commodity_type TEXT NOT NULL,
  weight REAL NOT NULL,
  unit TEXT NOT NULL,
  buyer_id TEXT NOT NULL,
  seller_id TEXT NOT NULL,
  gps_lat REAL NOT NULL,
  gps_lng REAL NOT NULL,
  gps_accuracy REAL,
  timestamp_utc TEXT NOT NULL,
  integrity_hash TEXT NOT NULL,
  sync_status TEXT NOT NULL DEFAULT 'pending'
    CHECK(sync_status IN ('pending', 'syncing', 'synced', 'failed')),
  agent_id TEXT NOT NULL,
  notes TEXT,
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  FOREIGN KEY (agent_id) REFERENCES agents(id)
);

CREATE TABLE IF NOT EXISTS transaction_images (
  id TEXT PRIMARY KEY,
  transaction_id TEXT NOT NULL,
  file_path TEXT NOT NULL,
  captured_at TEXT NOT NULL,
  gps_lat REAL NOT NULL,
  gps_lng REAL NOT NULL,
  image_type TEXT NOT NULL CHECK(image_type IN ('commodity', 'scale_proof', 'delivery_evidence')),
  FOREIGN KEY (transaction_id) REFERENCES transactions(id)
);

CREATE TABLE IF NOT EXISTS sync_queue (
  transaction_id TEXT PRIMARY KEY,
  retry_count INTEGER NOT NULL DEFAULT 0,
  last_attempt TEXT,
  status TEXT NOT NULL DEFAULT 'pending'
    CHECK(status IN ('pending', 'syncing', 'synced', 'failed')),
  FOREIGN KEY (transaction_id) REFERENCES transactions(id)
);

CREATE TABLE IF NOT EXISTS ai_inferences (
  id TEXT PRIMARY KEY,
  transaction_id TEXT NOT NULL,
  model_version TEXT NOT NULL,
  result TEXT NOT NULL,
  confidence REAL NOT NULL,
  inferred_at TEXT NOT NULL DEFAULT (datetime('now')),
  FOREIGN KEY (transaction_id) REFERENCES transactions(id)
);

CREATE TABLE IF NOT EXISTS integrity_alerts (
  id TEXT PRIMARY KEY,
  transaction_id TEXT NOT NULL,
  expected_hash TEXT NOT NULL,
  received_hash TEXT NOT NULL,
  flagged_at TEXT NOT NULL DEFAULT (datetime('now')),
  FOREIGN KEY (transaction_id) REFERENCES transactions(id)
);

-- Indexes for common query patterns
CREATE INDEX IF NOT EXISTS idx_transactions_sync_status ON transactions(sync_status);
CREATE INDEX IF NOT EXISTS idx_transactions_timestamp ON transactions(timestamp_utc);
CREATE INDEX IF NOT EXISTS idx_transactions_agent ON transactions(agent_id);
CREATE INDEX IF NOT EXISTS idx_images_transaction ON transaction_images(transaction_id);
CREATE INDEX IF NOT EXISTS idx_sync_queue_status ON sync_queue(status);
