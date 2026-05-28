package handlers

import (
	"fmt"
	"net/http"

	"github.com/gin-gonic/gin"

	"github.com/agroverify/edge-backend/internal/models"
	"github.com/agroverify/edge-backend/pkg/crypto"
)

// BatchSyncTransactions receives a batch of transactions from a field device,
// re-verifies the SHA-256 integrity hash on each, stores valid ones, and
// flags mismatches as integrity alerts.
func BatchSyncTransactions(c *gin.Context) {
	var req models.BatchSyncRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	response := models.BatchSyncResponse{
		Accepted: []string{},
		Rejected: []models.RejectedItem{},
	}

	for _, txn := range req.Transactions {
		expectedHash := crypto.GenerateTransactionHash(crypto.HashParams{
			Weight:       txn.Weight,
			GPSLat:       txn.GPSLat,
			GPSLng:       txn.GPSLng,
			TimestampUTC: txn.TimestampUTC,
			AgentID:      txn.AgentID,
		})

		if expectedHash != txn.IntegrityHash {
			// TODO: persist integrity alert and notify admin
			response.Rejected = append(response.Rejected, models.RejectedItem{
				ID:     txn.ID,
				Reason: fmt.Sprintf("integrity hash mismatch: expected %s, got %s", expectedHash[:8]+"...", txn.IntegrityHash[:8]+"..."),
			})
			continue
		}

		// TODO: persist to PostgreSQL via repository layer
		response.Accepted = append(response.Accepted, txn.ID)
	}

	c.JSON(http.StatusOK, response)
}

func GetTransaction(c *gin.Context) {
	id := c.Param("id")
	// TODO: fetch from repository
	c.JSON(http.StatusOK, gin.H{"id": id, "message": "not yet implemented"})
}
