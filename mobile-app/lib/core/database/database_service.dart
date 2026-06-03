import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

const _dbName = 'agroverify.db';
const _dbVersion = 1;

Database? _db;

Future<Database> openAppDatabase(String encryptionKey) async {
  if (_db != null) return _db!;

  final dir = await getApplicationDocumentsDirectory();
  final path = join(dir.path, _dbName);

  _db = await openDatabase(
    path,
    version: _dbVersion,
    password: encryptionKey,
    onCreate: _onCreate,
    onOpen: _seedIfEmpty,
  );

  return _db!;
}

Database getDatabase() {
  if (_db == null) throw StateError('Database not initialised. Call openAppDatabase() first.');
  return _db!;
}

Future<void> _seedIfEmpty(Database db) async {
  final rows = await db.query('agents', limit: 1);
  if (rows.isNotEmpty) return;
  await db.insert('agents', {
    'id': 'agent-dev-001',
    'name': 'Bassey Ekpenyong',
    'pin_hash': '1234',
    'region': 'Lagos',
    'cooperative_id': 'COOP-001',
    'role': 'field_agent',
    'last_active': DateTime.now().toUtc().toIso8601String(),
    'created_at': DateTime.now().toUtc().toIso8601String(),
  });
}

Future<void> _onCreate(Database db, int version) async {
  final batch = db.batch();

  batch.execute('''
    CREATE TABLE agents (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      pin_hash TEXT NOT NULL,
      region TEXT NOT NULL,
      cooperative_id TEXT NOT NULL,
      role TEXT NOT NULL CHECK(role IN ('field_agent','cooperative_manager','admin','enterprise')),
      last_active TEXT,
      created_at TEXT NOT NULL DEFAULT (datetime('now'))
    )
  ''');

  batch.execute('''
    CREATE TABLE transactions (
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
        CHECK(sync_status IN ('pending','syncing','synced','failed')),
      agent_id TEXT NOT NULL,
      notes TEXT,
      created_at TEXT NOT NULL DEFAULT (datetime('now')),
      FOREIGN KEY (agent_id) REFERENCES agents(id)
    )
  ''');

  batch.execute('''
    CREATE TABLE transaction_images (
      id TEXT PRIMARY KEY,
      transaction_id TEXT NOT NULL,
      file_path TEXT NOT NULL,
      captured_at TEXT NOT NULL,
      gps_lat REAL NOT NULL,
      gps_lng REAL NOT NULL,
      image_type TEXT NOT NULL CHECK(image_type IN ('commodity','scale_proof','delivery_evidence')),
      FOREIGN KEY (transaction_id) REFERENCES transactions(id)
    )
  ''');

  batch.execute('''
    CREATE TABLE sync_queue (
      transaction_id TEXT PRIMARY KEY,
      retry_count INTEGER NOT NULL DEFAULT 0,
      last_attempt TEXT,
      status TEXT NOT NULL DEFAULT 'pending'
        CHECK(status IN ('pending','syncing','synced','failed')),
      FOREIGN KEY (transaction_id) REFERENCES transactions(id)
    )
  ''');

  batch.execute('''
    CREATE TABLE ai_inferences (
      id TEXT PRIMARY KEY,
      transaction_id TEXT NOT NULL,
      model_version TEXT NOT NULL,
      result TEXT NOT NULL,
      confidence REAL NOT NULL,
      inferred_at TEXT NOT NULL DEFAULT (datetime('now')),
      FOREIGN KEY (transaction_id) REFERENCES transactions(id)
    )
  ''');

  batch.execute('''
    CREATE TABLE integrity_alerts (
      id TEXT PRIMARY KEY,
      transaction_id TEXT NOT NULL,
      expected_hash TEXT NOT NULL,
      received_hash TEXT NOT NULL,
      flagged_at TEXT NOT NULL DEFAULT (datetime('now')),
      FOREIGN KEY (transaction_id) REFERENCES transactions(id)
    )
  ''');

  batch.execute('CREATE INDEX idx_txn_sync ON transactions(sync_status)');
  batch.execute('CREATE INDEX idx_txn_time ON transactions(timestamp_utc)');
  batch.execute('CREATE INDEX idx_txn_agent ON transactions(agent_id)');
  batch.execute('CREATE INDEX idx_images_txn ON transaction_images(transaction_id)');
  batch.execute('CREATE INDEX idx_queue_status ON sync_queue(status)');

  // Seed a development agent for testing (PIN: 1234)
  batch.insert('agents', {
    'id': 'agent-dev-001',
    'name': 'Bassey Ekpenyong',
    'pin_hash': '1234',
    'region': 'Lagos',
    'cooperative_id': 'COOP-001',
    'role': 'field_agent',
    'last_active': DateTime.now().toUtc().toIso8601String(),
    'created_at': DateTime.now().toUtc().toIso8601String(),
  });

  await batch.commit(noResult: true);
}
