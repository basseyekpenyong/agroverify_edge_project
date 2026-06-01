import 'package:sqflite_sqlcipher/sqflite.dart';
import '../../../core/database/database_service.dart';

class ImageDao {
  final Database _db;
  ImageDao(this._db);

  factory ImageDao.fromSingleton() => ImageDao(getDatabase());

  Future<void> insert({
    required String id,
    required String transactionId,
    required String filePath,
    required String imageType,
    double? gpsLat,
    double? gpsLng,
  }) async {
    await _db.insert('transaction_images', {
      'id': id,
      'transaction_id': transactionId,
      'file_path': filePath,
      'captured_at': DateTime.now().toUtc().toIso8601String(),
      'gps_lat': gpsLat ?? 0.0,
      'gps_lng': gpsLng ?? 0.0,
      'image_type': imageType,
    });
  }

  Future<List<Map<String, dynamic>>> getForTransaction(String transactionId) =>
      _db.query(
        'transaction_images',
        where: 'transaction_id = ?',
        whereArgs: [transactionId],
        orderBy: 'captured_at ASC',
      );

  Future<void> delete(String id) =>
      _db.delete('transaction_images', where: 'id = ?', whereArgs: [id]);
}
