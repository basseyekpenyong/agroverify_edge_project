# AgroVerify Edge — System Architecture

## Component Overview

```
┌─────────────────────────────────────────────────────────┐
│                   MOBILE DEVICE (Android)                │
│                                                         │
│  Flutter UI (Riverpod + GoRouter)                       │
│    ↓                                                    │
│  SQLite (AES-256, sqflite_sqlcipher)                    │
│    ↓                                                    │
│  SHA-256 Hash Engine  ←→  AI Inference (TFLite INT8)   │
│    ↓                                                    │
│  Background Sync Worker (WorkManager)                   │
│    ↓ (when online)                                      │
└─────────────────────────────────────────────────────────┘
                         │ TLS 1.2+
                         ▼
┌─────────────────────────────────────────────────────────┐
│              CLOUD BACKEND (Python + FastAPI)            │
│                                                         │
│  REST API (/api/v1/transactions/batch)                  │
│    ↓                                                    │
│  SHA-256 Re-verification (crypto.py)                    │
│    ↓              ↓ (mismatch)                          │
│  PostgreSQL    IntegrityAlert → Admin Notification      │
│    ↓                                                    │
│  ERP Webhook (fires within 60s via BackgroundTasks)     │
│    ↓                                                    │
│  OTA Model Manifest (/api/v1/models/latest)             │
└─────────────────────────────────────────────────────────┘
```

## Key Design Decisions

| Decision | Choice | Rationale |
|---|---|---|
| Mobile framework | Flutter (Dart) | Native Android performance, mature tflite_flutter plugin, tight WorkManager integration |
| State management | Riverpod | Dart-idiomatic, compile-safe providers, no BuildContext dependency |
| Navigation | GoRouter | Official Flutter navigation, deep-link support, RBAC guards |
| Local DB | SQLite + sqflite_sqlcipher | AES-256 at rest, offline-first, battle-tested on Android |
| Backend | Python + FastAPI | Async-first, matches AI pipeline language (PyTorch), auto OpenAPI docs |
| Cloud DB | PostgreSQL + SQLAlchemy async | Reliable, JSONB support, asyncpg for high throughput |
| Hash algorithm | SHA-256 | Deterministic, collision-resistant, identical implementation on device and backend |
| AI runtime | TFLite INT8 | Smallest footprint, fastest inference on Android, offline |
| Auth | JWT (HS256, 8h expiry) + bcrypt PINs | Stateless, offline PIN cache, Android Keystore for token storage |

## Transaction Integrity Flow

1. Agent creates transaction on device
2. `hash_engine.dart` computes SHA-256(`weight|lat|lng|timestamp|agentId`)
3. Hash stored in local SQLite alongside transaction record
4. WorkManager syncs pending records when connectivity restored
5. `crypto.py` recomputes hash with identical canonical format
6. **Match** → accepted, stored in PostgreSQL, ERP webhook fired within 60s
7. **Mismatch** → `integrity_alerts` record created, admin notified within 60s

## API Endpoints

| Method | Path | Auth | Description |
|---|---|---|---|
| POST | `/api/v1/auth/login` | Public | Agent PIN login → JWT |
| POST | `/api/v1/transactions/batch` | JWT | Batch sync with hash verification |
| GET | `/api/v1/transactions/{id}` | JWT | Fetch verified transaction |
| POST | `/api/v1/agents` | Admin | Provision agent account |
| PATCH | `/api/v1/agents/{id}/status` | Admin | Activate / suspend agent |
| GET | `/api/v1/alerts/integrity` | Admin | List hash mismatch alerts |
| POST | `/api/v1/webhooks/erp` | Admin | Register ERP webhook URL |
| GET | `/api/v1/models/latest` | JWT | OTA model manifest |
| GET | `/health` | Public | Health check |

## Flutter Project Structure

```
mobile-app/lib/
  core/
    auth/rbac.dart              — UserRole enum + permission checks
    constants/                  — colours, commodity lists
    crypto/hash_engine.dart     — SHA-256 canonical hash
    database/
      database_service.dart     — openDatabase (AES-256 via sqflite_sqlcipher)
      transaction_dao.dart      — CRUD + sync queue management
    navigation/app_router.dart  — GoRouter with auth guards
  features/
    auth/                       — login screen, auth provider, agent model
    home/                       — dashboard with connectivity banner
    transactions/               — new/list/detail screens + Riverpod providers
    sync/                       — sync status dashboard
    settings/                   — account info + logout
```

## Backend Project Structure

```
backend/
  app/
    main.py                     — FastAPI app + router registration
    core/
      config.py                 — pydantic-settings (DATABASE_URL, SECRET_KEY)
      security.py               — JWT, bcrypt, role guards
      crypto.py                 — SHA-256 hash (mirrors hash_engine.dart)
    db/
      database.py               — async SQLAlchemy engine + session
      models.py                 — Agent, Transaction, IntegrityAlert, ErpWebhook, ModelManifest
    routers/
      auth.py                   — POST /auth/login
      transactions.py           — POST /batch, GET /:id + ERP webhook dispatch
      agents.py                 — POST /, PATCH /:id/status
      alerts.py                 — GET /integrity
      webhooks.py               — POST /erp
      ota.py                    — GET /models/latest
  migrations/
    001_initial_schema.sql      — PostgreSQL schema
```
