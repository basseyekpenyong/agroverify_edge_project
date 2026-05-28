package models

import "time"

type SyncStatus string

const (
	SyncStatusPending  SyncStatus = "pending"
	SyncStatusSyncing  SyncStatus = "syncing"
	SyncStatusSynced   SyncStatus = "synced"
	SyncStatusFailed   SyncStatus = "failed"
)

type Transaction struct {
	ID             string     `json:"id" db:"id"`
	CommodityType  string     `json:"commodityType" db:"commodity_type"`
	Weight         float64    `json:"weight" db:"weight"`
	Unit           string     `json:"unit" db:"unit"`
	BuyerID        string     `json:"buyerId" db:"buyer_id"`
	SellerID       string     `json:"sellerId" db:"seller_id"`
	GPSLat         float64    `json:"gpsLat" db:"gps_lat"`
	GPSLng         float64    `json:"gpsLng" db:"gps_lng"`
	GPSAccuracy    float64    `json:"gpsAccuracy" db:"gps_accuracy"`
	TimestampUTC   time.Time  `json:"timestampUtc" db:"timestamp_utc"`
	IntegrityHash  string     `json:"integrityHash" db:"integrity_hash"`
	SyncStatus     SyncStatus `json:"syncStatus" db:"sync_status"`
	AgentID        string     `json:"agentId" db:"agent_id"`
	Notes          *string    `json:"notes,omitempty" db:"notes"`
	CreatedAt      time.Time  `json:"createdAt" db:"created_at"`
}

type BatchSyncRequest struct {
	Transactions []Transaction `json:"transactions" binding:"required"`
}

type BatchSyncResponse struct {
	Accepted []string          `json:"accepted"`
	Rejected []RejectedItem    `json:"rejected"`
}

type RejectedItem struct {
	ID     string `json:"id"`
	Reason string `json:"reason"`
}
