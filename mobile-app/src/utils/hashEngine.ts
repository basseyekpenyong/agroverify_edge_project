import CryptoJS from 'crypto-js';

/**
 * Generates a SHA-256 integrity hash for a transaction.
 * Canonical format: weight|gps_lat|gps_lng|timestamp_utc|agent_id
 * GPS values fixed to 6 decimal places to avoid floating-point ambiguity.
 */
export function generateTransactionHash(params: {
  weight: number;
  gpsLat: number;
  gpsLng: number;
  timestampUtc: string;
  agentId: string;
}): string {
  const canonical = [
    params.weight.toString(),
    params.gpsLat.toFixed(6),
    params.gpsLng.toFixed(6),
    params.timestampUtc,
    params.agentId,
  ].join('|');

  return CryptoJS.SHA256(canonical).toString(CryptoJS.enc.Hex);
}

export function verifyTransactionHash(
  hash: string,
  params: Parameters<typeof generateTransactionHash>[0],
): boolean {
  return generateTransactionHash(params) === hash;
}
