package main

import (
	"log"
	"os"

	"github.com/gin-gonic/gin"
	"github.com/joho/godotenv"

	"github.com/agroverify/edge-backend/internal/handlers"
	"github.com/agroverify/edge-backend/internal/middleware"
)

func main() {
	if err := godotenv.Load(); err != nil {
		log.Println("No .env file found, using environment variables")
	}

	r := gin.Default()

	r.Use(middleware.CORSMiddleware())

	// Health check
	r.GET("/health", func(c *gin.Context) {
		c.JSON(200, gin.H{"status": "ok"})
	})

	// API v1
	v1 := r.Group("/api/v1")
	{
		// Auth
		v1.POST("/auth/login", handlers.Login)

		// Transactions (JWT protected)
		txn := v1.Group("/transactions", middleware.JWTAuth())
		{
			txn.POST("/batch", handlers.BatchSyncTransactions)
			txn.GET("/:id", handlers.GetTransaction)
		}

		// Agents (admin only)
		agents := v1.Group("/agents", middleware.JWTAuth(), middleware.RequireRole("admin"))
		{
			agents.POST("", handlers.CreateAgent)
			agents.PATCH("/:id/status", handlers.UpdateAgentStatus)
		}

		// Integrity alerts (admin only)
		alerts := v1.Group("/alerts", middleware.JWTAuth(), middleware.RequireRole("admin"))
		{
			alerts.GET("/integrity", handlers.ListIntegrityAlerts)
		}

		// Webhooks
		webhooks := v1.Group("/webhooks", middleware.JWTAuth(), middleware.RequireRole("admin"))
		{
			webhooks.POST("/erp", handlers.RegisterERPWebhook)
		}

		// Models (OTA updates)
		v1.GET("/models/latest", handlers.GetLatestModelManifest)
	}

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	log.Printf("AgroVerify Edge backend starting on :%s", port)
	if err := r.Run(":" + port); err != nil {
		log.Fatalf("Failed to start server: %v", err)
	}
}
