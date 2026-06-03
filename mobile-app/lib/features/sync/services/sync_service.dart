import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/database/database_service.dart';
import '../../../core/database/transaction_dao.dart';

const _keyApiBaseUrl = 'api_base_url';
const _keyApiToken = 'api_token';
// Android emulator → host; override in Settings for a real device
const defaultApiBaseUrl = 'http://10.0.2.2:8000';

class SyncResult {
  final int accepted;
  final int rejected;
  final String? error;

  const SyncResult({required this.accepted, required this.rejected, this.error});

  bool get hasError => error != null;
  bool get isClean => !hasError && rejected == 0;
}

class SyncService {
  static const _storage = FlutterSecureStorage();

  Future<SyncResult> sync() async {
    final baseUrl = await _storage.read(key: _keyApiBaseUrl) ?? defaultApiBaseUrl;
    final token = await _storage.read(key: _keyApiToken);

    final dao = TransactionDao.fromSingleton();
    final pending = await dao.getPending();
    if (pending.isEmpty) return const SyncResult(accepted: 0, rejected: 0);

    final dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
    ));

    try {
      final response = await dio.post('/api/v1/transactions/batch', data: {
        'transactions': pending
            .map((row) => {
                  'id': row['id'],
                  'commodity_type': row['commodity_type'],
                  'weight': row['weight'],
                  'unit': row['unit'],
                  'buyer_id': row['buyer_id'],
                  'seller_id': row['seller_id'],
                  'gps_lat': row['gps_lat'],
                  'gps_lng': row['gps_lng'],
                  'gps_accuracy': row['gps_accuracy'],
                  'timestamp_utc': row['timestamp_utc'],
                  'integrity_hash': row['integrity_hash'],
                  'agent_id': row['agent_id'],
                  'notes': row['notes'],
                })
            .toList(),
      });

      final accepted = List<String>.from(response.data['accepted'] ?? []);
      final rejected = (response.data['rejected'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      for (final id in accepted) {
        await dao.markSynced(id);
      }
      for (final r in rejected) {
        await dao.markFailed(r['id'] as String);
      }

      return SyncResult(accepted: accepted.length, rejected: rejected.length);
    } on DioException catch (e) {
      final msg = e.response != null
          ? 'Server error ${e.response!.statusCode}'
          : e.message ?? 'Network error';
      return SyncResult(accepted: 0, rejected: 0, error: msg);
    }
  }

  static Future<void> saveApiConfig({
    required String baseUrl,
    required String token,
  }) async {
    await _storage.write(key: _keyApiBaseUrl, value: baseUrl.trim());
    await _storage.write(key: _keyApiToken, value: token.trim());
  }

  static Future<({String baseUrl, String token})> loadApiConfig() async {
    return (
      baseUrl: await _storage.read(key: _keyApiBaseUrl) ?? defaultApiBaseUrl,
      token: await _storage.read(key: _keyApiToken) ?? '',
    );
  }
}

/// Runs a sync from a background isolate (WorkManager callback).
/// Opens the DB using the stored encryption key, then syncs.
Future<bool> runBackgroundSync() async {
  try {
    const storage = FlutterSecureStorage();
    final encKey = await storage.read(key: 'db_enc_key');
    if (encKey == null) return false;

    await openAppDatabase(encKey);
    final result = await SyncService().sync();
    return !result.hasError;
  } catch (_) {
    return false;
  }
}
