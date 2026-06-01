import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Canonical format: weight|gps_lat|gps_lng|timestamp_utc|agent_id
/// GPS values fixed to 6 decimal places to prevent floating-point ambiguity.
String generateTransactionHash({
  required double weight,
  required double gpsLat,
  required double gpsLng,
  required String timestampUtc,
  required String agentId,
}) {
  final canonical = [
    weight.toString(),
    gpsLat.toStringAsFixed(6),
    gpsLng.toStringAsFixed(6),
    timestampUtc,
    agentId,
  ].join('|');

  final bytes = utf8.encode(canonical);
  return sha256.convert(bytes).toString();
}

bool verifyTransactionHash({
  required String hash,
  required double weight,
  required double gpsLat,
  required double gpsLng,
  required String timestampUtc,
  required String agentId,
}) {
  return generateTransactionHash(
        weight: weight,
        gpsLat: gpsLat,
        gpsLng: gpsLng,
        timestampUtc: timestampUtc,
        agentId: agentId,
      ) ==
      hash;
}
