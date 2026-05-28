# AgroVerify Edge — System Architecture

## Component Overview

```
┌─────────────────────────────────────────────────────────┐
│                   MOBILE DEVICE (Android)                │
│                                                         │
│  React Native UI                                        │
│    ↓                                                    │
│  Redux Store (auth / transactions / sync)               │
│    ↓                                                    │
│  SQLite (AES-256, SQLCipher)                            │
│    ↓                                                    │
│  SHA-256 Hash Engine  ←→  AI Inference (TFLite INT8)   │
│    ↓                                                    │
│  Background Sync Worker (WorkManager)                   │
│    ↓ (when online)                                      │
└─────────────────────────────────────────────────────────┘
                         │ TLS 1.2+
                         ▼
┌─────────────────────────────────────────────────────────┐
│                   CLOUD BACKEND (Go + Gin)               │
│                                                         │
│  REST API (/api/v1/transactions/batch)                  │
│    ↓                                                    │
│  SHA-256 Re-verification                                │
│    ↓              ↓ (mismatch)                          │
│  PostgreSQL    Integrity Alert → Admin Notification     │
│    ↓                                                    │
│  ERP Webhook (fires within 60s)                         │
│    ↓                                                    │
│  OTA Model Manifest (/api/v1/models/latest)             │
└─────────────────────────────────────────────────────────┘
```

## Key Design Decisions

| Decision | Choice | Rationale |
|---|---|---|
| Mobile framework | React Native | Cross-platform, large ecosystem, JS/TS familiarity |
| Local DB | SQLite + SQLCipher | Only embedded DB viable on Android; AES-256 via SQLCipher |
| Backend | Go + Gin | Fast, single binary, excellent concurrency for batch sync |
| Cloud DB | PostgreSQL | Reliable, JSONB for flexible payloads, strong indexing |
| State management | Redux Toolkit | Predictable, DevTools support, async thunks for sync |
| Hash algorithm | SHA-256 | Widely supported, collision-resistant, deterministic |
| AI runtime | TFLite INT8 | Smallest footprint, fastest inference on Android, offline |

## Transaction Integrity Flow

1. Agent creates transaction on device
2. `hashEngine.ts` computes SHA-256(`weight|lat|lng|timestamp|agentId`)
3. Hash stored in local SQLite alongside transaction
4. On sync: backend receives transaction batch
5. `pkg/crypto/hash.go` recomputes hash with identical canonical format
6. Match → accepted, stored in PostgreSQL
7. Mismatch → `integrity_alerts` record created, admin notified within 60s
