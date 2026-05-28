import SQLite from 'react-native-sqlite-storage';

SQLite.enablePromise(true);

const DB_NAME = 'agroverify.db';

let db: SQLite.SQLiteDatabase | null = null;

export async function openDatabase(encryptionKey: string): Promise<SQLite.SQLiteDatabase> {
  if (db) return db;

  db = await SQLite.openDatabase({
    name: DB_NAME,
    location: 'default',
    // SQLCipher key derived from agent PIN via PBKDF2 (see authService)
    key: encryptionKey,
  });

  await initSchema(db);
  return db;
}

async function initSchema(database: SQLite.SQLiteDatabase): Promise<void> {
  await database.transaction(tx => {
    tx.executeSql(`CREATE TABLE IF NOT EXISTS agents (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      pin_hash TEXT NOT NULL,
      region TEXT NOT NULL,
      cooperative_id TEXT NOT NULL,
      role TEXT NOT NULL,
      last_active TEXT,
      created_at TEXT NOT NULL DEFAULT (datetime('now'))
    )`);

    tx.executeSql(`CREATE TABLE IF NOT EXISTS transactions (
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
      sync_status TEXT NOT NULL DEFAULT 'pending',
      agent_id TEXT NOT NULL,
      notes TEXT,
      created_at TEXT NOT NULL DEFAULT (datetime('now'))
    )`);

    tx.executeSql(`CREATE TABLE IF NOT EXISTS transaction_images (
      id TEXT PRIMARY KEY,
      transaction_id TEXT NOT NULL,
      file_path TEXT NOT NULL,
      captured_at TEXT NOT NULL,
      gps_lat REAL NOT NULL,
      gps_lng REAL NOT NULL,
      image_type TEXT NOT NULL
    )`);

    tx.executeSql(`CREATE TABLE IF NOT EXISTS sync_queue (
      transaction_id TEXT PRIMARY KEY,
      retry_count INTEGER NOT NULL DEFAULT 0,
      last_attempt TEXT,
      status TEXT NOT NULL DEFAULT 'pending'
    )`);

    tx.executeSql(`CREATE TABLE IF NOT EXISTS ai_inferences (
      id TEXT PRIMARY KEY,
      transaction_id TEXT NOT NULL,
      model_version TEXT NOT NULL,
      result TEXT NOT NULL,
      confidence REAL NOT NULL,
      inferred_at TEXT NOT NULL DEFAULT (datetime('now'))
    )`);

    tx.executeSql(`CREATE INDEX IF NOT EXISTS idx_transactions_sync_status ON transactions(sync_status)`);
    tx.executeSql(`CREATE INDEX IF NOT EXISTS idx_transactions_timestamp ON transactions(timestamp_utc)`);
    tx.executeSql(`CREATE INDEX IF NOT EXISTS idx_sync_queue_status ON sync_queue(status)`);
  });
}

export function getDatabase(): SQLite.SQLiteDatabase {
  if (!db) throw new Error('Database not initialised. Call openDatabase() first.');
  return db;
}
