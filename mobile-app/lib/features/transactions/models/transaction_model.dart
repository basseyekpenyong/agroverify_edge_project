class TransactionModel {
  final String id;
  final String commodityType;
  final double weight;
  final String unit;
  final String buyerId;
  final String sellerId;
  final double gpsLat;
  final double gpsLng;
  final double? gpsAccuracy;
  final String timestampUtc;
  final String integrityHash;
  final String syncStatus;
  final String agentId;
  final String? notes;
  final DateTime createdAt;

  const TransactionModel({
    required this.id,
    required this.commodityType,
    required this.weight,
    required this.unit,
    required this.buyerId,
    required this.sellerId,
    required this.gpsLat,
    required this.gpsLng,
    this.gpsAccuracy,
    required this.timestampUtc,
    required this.integrityHash,
    required this.syncStatus,
    required this.agentId,
    this.notes,
    required this.createdAt,
  });

  bool get isSynced => syncStatus == 'synced';
  bool get isPending => syncStatus == 'pending';

  factory TransactionModel.fromMap(Map<String, dynamic> m) => TransactionModel(
        id: m['id'] as String,
        commodityType: m['commodity_type'] as String,
        weight: (m['weight'] as num).toDouble(),
        unit: m['unit'] as String,
        buyerId: m['buyer_id'] as String,
        sellerId: m['seller_id'] as String,
        gpsLat: (m['gps_lat'] as num).toDouble(),
        gpsLng: (m['gps_lng'] as num).toDouble(),
        gpsAccuracy: m['gps_accuracy'] != null ? (m['gps_accuracy'] as num).toDouble() : null,
        timestampUtc: m['timestamp_utc'] as String,
        integrityHash: m['integrity_hash'] as String,
        syncStatus: m['sync_status'] as String,
        agentId: m['agent_id'] as String,
        notes: m['notes'] as String?,
        createdAt: DateTime.parse(m['created_at'] as String),
      );
}
