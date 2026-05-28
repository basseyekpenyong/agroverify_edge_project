package crypto

import (
	"crypto/sha256"
	"fmt"
	"time"
)

type HashParams struct {
	Weight       float64
	GPSLat       float64
	GPSLng       float64
	TimestampUTC time.Time
	AgentID      string
}

// GenerateTransactionHash produces a SHA-256 hash identical to the one
// generated on the mobile device. Canonical format:
//
//	weight|gps_lat|gps_lng|timestamp_utc|agent_id
//
// GPS values are formatted to 6 decimal places to avoid floating-point
// representation differences between Go and JavaScript.
func GenerateTransactionHash(p HashParams) string {
	canonical := fmt.Sprintf("%v|%.6f|%.6f|%s|%s",
		p.Weight,
		p.GPSLat,
		p.GPSLng,
		p.TimestampUTC.UTC().Format(time.RFC3339Nano),
		p.AgentID,
	)
	sum := sha256.Sum256([]byte(canonical))
	return fmt.Sprintf("%x", sum)
}
