import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../crypto/hash_engine.dart';
import 'database_service.dart';

const _uuid = Uuid();

class TransactionDao {
  final Database _db;
  TransactionDao(this._db);

  factory TransactionDao.fromSingleton() => TransactionDao(getDatabase());

  Future<String> insert({
    required String commodityType,
    required double weight,
    required String unit,
    required String buyerId,
    required String sellerId,
    required double gpsLat,
    required double gpsLng,
    double? gpsAccuracy,
    required String agentId,
    String? notes,
  }) async {
    final id = _uuid.v4();
    final timestamp = DateTime.now().toUtc().toIso8601String();
    final hash = generateTransactionHash(
      weight: weight,
      gpsLat: gpsLat,
      gpsLng: gpsLng,
      timestampUtc: timestamp,
      agentId: agentId,
    );

    await _db.insert('transactions', {
      'id': id,
      'commodity_type': commodityType,
      'weight': weight,
      'unit': unit,
      'buyer_id': buyerId,
      'seller_id': sellerId,
      'gps_lat': gpsLat,
      'gps_lng': gpsLng,
      'gps_accuracy': gpsAccuracy,
      'timestamp_utc': timestamp,
      'integrity_hash': hash,
      'sync_status': 'pending',
      'agent_id': agentId,
      'notes': notes,
    });

    await _db.insert('sync_queue', {
      'transaction_id': id,
      'retry_count': 0,
      'status': 'pending',
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    return id;
  }

  Future<List<Map<String, dynamic>>> getPending() => _db.query(
        'transactions',
        where: 'sync_status = ?',
        whereArgs: ['pending'],
        orderBy: 'created_at DESC',
      );

  Future<List<Map<String, dynamic>>> getAll({String? agentId}) {
    if (agentId != null) {
      return _db.query(
        'transactions',
        where: 'agent_id = ?',
        whereArgs: [agentId],
        orderBy: 'created_at DESC',
      );
    }
    return _db.query('transactions', orderBy: 'created_at DESC');
  }

  Future<Map<String, dynamic>?> getById(String id) async {
    final rows = await _db.query('transactions', where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : rows.first;
  }

  Future<void> markSynced(String id) => _db.update(
        'transactions',
        {'sync_status': 'synced'},
        where: 'id = ? AND sync_status != ?',
        whereArgs: [id, 'synced'],
      );

  Future<void> markFailed(String id) => _db.update(
        'transactions',
        {'sync_status': 'failed'},
        where: 'id = ?',
        whereArgs: [id],
      );
}
