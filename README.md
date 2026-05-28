# AgroVerify Edge

> Offline-first multimodal agricultural supply chain verification platform powered by Edge AI.

---

## Overview

AgroVerify Edge is a B2B mobile-first infrastructure platform designed for agricultural supply chains operating in low-connectivity environments across emerging markets.

The platform lets field buying agents, commodity aggregators, cooperatives, and enterprise agribusinesses securely capture, validate, and sync transaction data using offline-first workflows and on-device AI.

AgroVerify Edge addresses critical supply chain problems, including:

- Manual entry errors and commodity fraud
- No internet connectivity at the point of capture
- No tamper-evident transaction records
- Delayed reporting and zero traceability

By combining multimodal AI (voice + vision), secure local databases, and lightweight edge computing, AgroVerify Edge creates a tamper-resistant operational verification layer for agricultural commerce.

---

## Core Features

### Offline-First Architecture

- Full operation without internet access
- Local SQLite database with AES-256 encryption (SQLCipher)
- Background synchronization when connectivity returns
- Optimized for rural low-connectivity deployment

### Multilingual Voice Processing

Supports local African language processing:

- Hausa
- Igbo
- Yoruba
- Nigerian Pidgin English

Using Whisper Tiny (INT8 quantized), running fully offline on-device.

### Visual Verification System

Capture and validate per transaction:

- Commodity photos (AI-classified on-device)
- Weighing scale proof
- GPS coordinates with an accuracy indicator
- UTC timestamp
- Delivery evidence

### Data Integrity Protection

Each transaction generates a SHA-256 hash combining:

- Weight
- GPS coordinates (lat/lng to 6 decimal places)
- UTC timestamp
- Agent ID

The same hash is recomputed on the cloud backend at the time of sync. Any mismatch triggers an integrity alert to the system administrator within 60 seconds.

### Edge AI — Voice & Vision

- **Voice:** Whisper Tiny → TFLite INT8, offline speech-to-text in 4 languages
- **Vision:** MobileNetV3 → ONNX → TFLite INT8, classifies 10+ commodity types
- Both models fit within 50MB of on-device storage
- OTA model update support (no app store release required)

### Smart Background Synchronization

- Android WorkManager background sync job (non-blocking)
- Network-aware: fires automatically on connectivity restore
- Partial sync: only unsynced records transmitted
- Exponential backoff retry (max 5 attempts)
- ERP webhook notifications within 60 seconds of verified sync
- TLS 1.2+ encrypted transmission

---

## System Architecture

```
Android Device
  React Native UI
    ↓
  Redux Store (auth / transactions/sync)
    ↓
  SQLite — AES-256 encrypted (SQLCipher)
    ↓
  SHA-256 Hash Engine  ←→  TFLite INT8 AI Models
    ↓
  Background Sync Worker (WorkManager)
    ↓  (TLS 1.2+, when online)

Cloud Backend (Go + Gin)
  POST /api/v1/transactions/batch
    ↓
  SHA-256 Re-verification
    ↓              ↓ mismatch
  PostgreSQL    Integrity Alert → Admin (60s)
    ↓
  ERP Webhook
    ↓
  GET /api/v1/models/latest  (OTA model updates)
```

---

## Technology Stack

### Mobile App

| Layer | Technology |
|---|---|
| Framework | React Native 0.76 (TypeScript) |
| Navigation | React Navigation v6 |
| State management | Redux Toolkit |
| Local database | SQLite + SQLCipher (AES-256) |
| AI inference | TensorFlow Lite INT8 |
| GPS | react-native-geolocation-service |
| Camera | react-native-image-picker |
| Voice | react-native-audio-recorder-player + Whisper Tiny |
| Sync worker | react-native-background-fetch + Android WorkManager |
| Hashing | crypto-js (SHA-256) |

### Backend API

| Layer | Technology |
|---|---|
| Language | Go 1.23 |
| Framework | Gin |
| Database | PostgreSQL 16 |
| Auth | JWT (golang-jwt/jwt) |
| Migrations | golang-migrate |
| Containerization | Docker |

### AI / Machine Learning

| Component | Technology |
|---|---|
| Model training | PyTorch + MobileNetV3 |
| Export pipeline | PyTorch → ONNX → TensorFlow → TFLite |
| Quantization | INT8 post-training quantization |
| Voice model | OpenAI Whisper Tiny |
| On-device runtime | TensorFlow Lite |

### DevOps

- GitHub Actions CI (lint + test + Docker build on every PR)
- Docker Compose (local backend + PostgreSQL)
- Planned: Cloud deployment (GCP / AWS)

---

## AI Model Pipeline

```
1. Train MobileNetV3 in PyTorch (10 commodity classes)
2. Export to ONNX
3. Convert ONNX → TensorFlow SavedModel (onnx-tf)
4. Apply INT8 post-training quantization
5. Export .tflite with class label metadata
6. Bundle in mobile app / serve via OTA update endpoint
```

---

## Project Structure

```
agroverify_edge_project/
│
├── mobile-app/                    # React Native app
│   ├── src/
│   │   ├── screens/               # Login, Home, Transaction, Sync, Settings
│   │   ├── navigation/            # Stack + Tab navigator (RBAC guards)
│   │   ├── store/                 # Redux slices (auth, transactions, sync)
│   │   ├── services/database/     # SQLite DAO + schema
│   │   ├── utils/hashEngine.ts    # SHA-256 integrity hash
│   │   ├── constants/             # Colors, commodities, languages
│   │   └── types/                 # Shared TypeScript types
│   ├── package.json
│   └── tsconfig.json
│
├── backend/                       # Go + Gin REST API
│   ├── cmd/server/main.go         # Entry point + routes
│   ├── internal/
│   │   ├── handlers/              # Transaction batch sync, agents, alerts
│   │   ├── middleware/            # JWT auth, RBAC, CORS
│   │   └── models/                # Transaction, Agent structs
│   ├── pkg/crypto/hash.go         # SHA-256 (matches mobile canonical format)
│   ├── migrations/                # PostgreSQL schema
│   ├── Dockerfile
│   └── go.mod
│
├── ai-models/                     # ML training + export pipeline
│   ├── vision/commodity_classifier/
│   │   ├── train.py               # PyTorch MobileNetV3 training
│   │   └── export_tflite.py       # ONNX → TFLite INT8 export
│   └── requirements.txt
│
├── docs/
│   └── architecture.md
│
├── .github/workflows/ci.yml       # GitHub Actions CI
├── docker-compose.yml             # Local backend + PostgreSQL
├── .gitignore
├── REQUIREMENTS.md                # Full Software Requirements Specification
└── README.md
```

---

## Development Roadmap

### Milestone 1 — 2-Week MVP (Jun 2026)

- System architecture & security design
- Flutter app scaffold with routing and RBAC stubs
- AES-256 encrypted SQLite database
- Transaction capture UI (commodity, weight, GPS, images)
- SHA-256 integrity hash engine
- Outdoor high-contrast UI theme

### Milestone 2 — Edge AI Foundation (Jul 2026)

- Whisper Tiny offline speech-to-text (Hausa, Igbo, Yoruba, Pidgin)
- Commodity image classifier (PyTorch → TFLite INT8)
- OTA model update system

### Milestone 3 — Sync & ERP Integration (Sep 2026)

- Go + Gin backend with PostgreSQL
- Android WorkManager background sync
- ERP webhook notifications
- End-to-end hash integrity verification

### Milestone 4 — Enterprise Hardening (Nov 2026)

- Full RBAC enforcement
- Cooperative Manager reporting dashboard
- OWASP Mobile Top 10 security audit

### Milestone 5 — Production Launch (Dec 2026)

- Corporate pilot program (up to 3 cooperatives)
- Fraud reduction analytics dashboard

---

## Security & Integrity Protocol

- Transactions hashed on-device (SHA-256) before sync
- Hash recomputed on backend at ingest — mismatch = integrity alert
- Local database encrypted at rest (AES-256 via SQLCipher)
- API credentials stored in Android Hardware Keystore
- All cloud communication over TLS 1.2+
- OWASP Mobile Top 10 audit before production release

---

## Getting Started

### Prerequisites

| Tool | Version | Download |
|---|---|---|
| Node.js | 20 LTS | nodejs.org |
| React Native CLI | latest | `npm i -g react-native` |
| Go | 1.23+ | go.dev/dl |
| Android Studio | latest | developer.android.com |
| Docker Desktop | latest | docker.com |
| Python | 3.11+ | python.org (for AI models) |

### Clone the Repository

```bash
git clone https://github.com/basseyekpenyong/agroverify_edge_project.git
cd agroverify_edge_project
```

### Start the Backend (Docker)

```bash
docker compose up
```

Backend runs at `http://localhost:8080`. PostgreSQL runs at `localhost:5432`.

### Run the Mobile App

```bash
cd mobile-app
npm install
npx react-native run-android
```

### Set Up AI Models

```bash
cd ai-models
python -m venv venv
venv\Scripts\activate       # Windows
pip install -r requirements.txt
```

---

## Use Cases

- Agricultural commodity verification at the farm gate
- Cooperative transaction management
- Rural logistics tracking
- FMCG procurement systems
- Offline field agent operations
- Fraud reduction in agricultural supply chains

---

## Future Enhancements

- Blockchain audit trails
- Satellite connectivity fallback (Starlink)
- AI quality grading (grade A/B/C)
- QR/NFC commodity tagging
- Biometric field agent verification
- Real-time fraud scoring engine

---

## Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/your-feature.`
3. Commit your changes: `git commit -m "Add your feature"`
4. Push to your branch: `git push origin feature/your-feature.`
5. Open a Pull Request

---

## License

MIT License

---

## Author

Developed as part of the AgroVerify Edge Project — building offline-first verification infrastructure for emerging-market agricultural supply chains.

---

## Vision

AgroVerify Edge aims to become the trusted infrastructure layer for secure agricultural transactions across low-connectivity regions worldwide.
