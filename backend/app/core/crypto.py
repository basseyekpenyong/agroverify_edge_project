import hashlib


def compute_transaction_hash(weight: float, gps_lat: float, gps_lng: float, timestamp_utc: str, agent_id: str) -> str:
    """Canonical format mirrors mobile hash_engine.dart: weight|lat|lng|timestamp|agent_id"""
    canonical = "|".join([
        str(weight),
        f"{gps_lat:.6f}",
        f"{gps_lng:.6f}",
        timestamp_utc,
        agent_id,
    ])
    return hashlib.sha256(canonical.encode()).hexdigest()


def verify_transaction_hash(
    expected_hash: str,
    weight: float,
    gps_lat: float,
    gps_lng: float,
    timestamp_utc: str,
    agent_id: str,
) -> bool:
    return compute_transaction_hash(weight, gps_lat, gps_lng, timestamp_utc, agent_id) == expected_hash
