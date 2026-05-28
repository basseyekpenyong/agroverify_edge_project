# AgroVerify Edge — Software Requirements Specification (SRS)

**Version:** 1.0  
**Date:** 2026-05-28  
**Status:** Draft

---

## 1. Purpose

This document defines the functional requirements, non-functional requirements, user roles, and acceptance criteria for the AgroVerify Edge platform — an offline-first multimodal agricultural supply chain verification system targeting low-connectivity emerging markets.

---

## 2. Stakeholders & User Roles

| Role | Description |
|---|---|
| **Field Buying Agent** | Mobile field worker recording commodity transactions at farm/aggregation points |
| **Cooperative Manager** | Oversees multiple agents and validates aggregated transaction data |
| **Enterprise Agribusiness** | B2B buyer consuming verified supply chain data via ERP integration |
| **System Administrator** | Manages user access, reviews integrity alerts, configures sync rules |
| **Platform Operator** | Anthropic/Cobalt internal team managing infrastructure and AI model updates |

---

## 3. Functional Requirements

### 3.1 Offline-First Data Engine

| ID | Requirement | Priority |
|---|---|---|
| F-OFL-01 | The app must operate fully (capture, store, validate) without any internet connection | Critical |
| F-OFL-02 | All transaction records must be stored in a local encrypted SQLite database | Critical |
| F-OFL-03 | The app must queue all unsynced transactions and sync automatically when connectivity is restored | Critical |
| F-OFL-04 | The sync engine must implement exponential backoff retry logic on failed sync attempts | High |
| F-OFL-05 | The app must display a connectivity status indicator (offline / online / syncing) at all times | High |
| F-OFL-06 | Offline storage must support a minimum of 10,000 transactions before sync is required | Medium |

---

### 3.2 Transaction Capture

| ID | Requirement | Priority |
|---|---|---|
| F-TXN-01 | A field agent must be able to create a new commodity transaction record with: commodity type, weight, unit, buyer/seller identity, GPS coordinates, timestamp | Critical |
| F-TXN-02 | The app must auto-capture GPS coordinates at the moment of transaction creation | Critical |
| F-TXN-03 | The app must auto-stamp a tamper-evident UTC timestamp on each transaction | Critical |
| F-TXN-04 | Each transaction must be assigned a unique transaction ID (UUID) generated on-device | Critical |
| F-TXN-05 | Agents must be able to attach one or more images per transaction (commodity photo, scale proof, delivery evidence) | High |
| F-TXN-06 | Agents must be able to edit a transaction before it is synced; edits must re-trigger the integrity hash | High |
| F-TXN-07 | Synced transactions must be locked (read-only) on the device | High |

---

### 3.3 Multilingual Voice Input

| ID | Requirement | Priority |
|---|---|---|
| F-VCE-01 | The app must support voice-to-text field logging for transaction data entry | Critical |
| F-VCE-02 | Voice recognition must operate fully offline using an on-device speech model (Whisper Tiny or equivalent) | Critical |
| F-VCE-03 | The app must support the following languages: Hausa, Igbo, Yoruba, Nigerian Pidgin English | Critical |
| F-VCE-04 | Voice transcription output must be editable before submission | High |
| F-VCE-05 | The speech model must process audio in under 3 seconds on a mid-range Android device (4GB RAM) | High |
| F-VCE-06 | The app must support audio buffering to handle brief recording interruptions | Medium |

---

### 3.4 Visual Verification System

| ID | Requirement | Priority |
|---|---|---|
| F-VIS-01 | The app must allow photo capture directly from the camera for each transaction | Critical |
| F-VIS-02 | Captured images must be stored locally and linked to the transaction record by UUID | Critical |
| F-VIS-03 | The app must capture and embed GPS metadata in each photo at the time of capture | High |
| F-VIS-04 | The app must perform on-device AI classification to confirm that the image matches the declared commodity type | High |
| F-VIS-05 | The app must support scale/weighbridge proof capture (photo of scale display) | High |
| F-VIS-06 | The UI must be readable under direct outdoor sunlight (high contrast, large text mode) | High |
| F-VIS-07 | Images must be compressed on-device before storage to limit disk usage per transaction | Medium |

---

### 3.5 Data Integrity & Fraud Prevention

| ID | Requirement | Priority |
|---|---|---|
| F-INT-01 | Each transaction must generate a cryptographic hash (SHA-256 minimum) combining: weight, GPS coordinates, UTC timestamp, and agent ID | Critical |
| F-INT-02 | The hash must be stored alongside the transaction record in the local database | Critical |
| F-INT-03 | On sync, the cloud backend must re-verify the hash against the transmitted data | Critical |
| F-INT-04 | Any hash mismatch must trigger an integrity alert to the System Administrator | Critical |
| F-INT-05 | The integrity hash must be regenerated if an unsynced transaction is edited | High |
| F-INT-06 | The platform must log all integrity alerts with the original and received values for audit | High |

---

### 3.6 Edge AI Inference Engine

| ID | Requirement | Priority |
|---|---|---|
| F-AI-01 | All AI inference (voice + vision) must run fully on-device with no cloud dependency | Critical |
| F-AI-02 | AI models must be delivered in TensorFlow Lite (.tflite) format | Critical |
| F-AI-03 | Models must use INT8 quantization to meet memory and latency targets | Critical |
| F-AI-04 | The vision model must classify at least 10 common commodity types (e.g., maize, cassava, sorghum, rice, soy, groundnuts) | High |
| F-AI-05 | Model inference for image classification must complete in under 2 seconds on target hardware | High |
| F-AI-06 | The app must support over-the-air (OTA) model updates when connectivity is available | Medium |
| F-AI-07 | AI models must be versioned; the device must log which model version produced each inference result | Medium |

---

### 3.7 Background Sync & ERP Integration

| ID | Requirement | Priority |
|---|---|---|
| F-SYN-01 | The sync engine must run as a background service and not block the UI | Critical |
| F-SYN-02 | The sync engine must detect available network connectivity and initiate sync automatically | Critical |
| F-SYN-03 | The platform must expose a REST API for ERP systems to pull verified transaction data | High |
| F-SYN-04 | The backend must support webhook callbacks to notify ERP systems of new verified transactions | High |
| F-SYN-05 | The sync payload must be end-to-end encrypted in transit (TLS 1.2 minimum) | High |
| F-SYN-06 | The sync engine must support partial sync (only unsynced records) to minimize bandwidth consumption | High |
| F-SYN-07 | The platform must provide a sync status dashboard accessible to Cooperative Managers | Medium |

---

### 3.8 User Authentication & Access Control

| ID | Requirement | Priority |
|---|---|---|
| F-AUTH-01 | All users must authenticate with a username and PIN before accessing any transaction data | Critical |
| F-AUTH-02 | The app must support offline authentication (credentials cached securely on-device) | Critical |
| F-AUTH-03 | Sessions must expire after 8 hours of inactivity | High |
| F-AUTH-04 | System Administrators must be able to provision, suspend, and revoke agent accounts remotely | High |
| F-AUTH-05 | Each agent account must be scoped to a specific geographic region and cooperative | High |
| F-AUTH-06 | Role-based access control (RBAC) must restrict data visibility by user role | High |

---

### 3.9 Reporting & Analytics Dashboard

| ID | Requirement | Priority |
|---|---|---|
| F-RPT-01 | Cooperative Managers must be able to view a daily transaction summary by agent and commodity | High |
| F-RPT-02 | The dashboard must surface integrity alert counts and unresolved fraud flags | High |
| F-RPT-03 | The platform must generate exportable transaction reports in CSV and PDF format | Medium |
| F-RPT-04 | The dashboard must display sync lag (time between transaction creation and sync completion) | Medium |

---

## 4. Non-Functional Requirements

### 4.1 Performance

| ID | Requirement |
|---|---|
| NF-PERF-01 | App cold start time must be under 3 seconds on a mid-range Android device (e.g., 4GB RAM, Snapdragon 665-class) |
| NF-PERF-02 | Transaction record creation (including hash generation) must complete in under 1 second |
| NF-PERF-03 | Image classification inference must complete in under 2 seconds |
| NF-PERF-04 | Speech transcription must complete in under 3 seconds for a 10-second audio clip |
| NF-PERF-05 | The app must not consume more than 200MB of RAM during normal operation |

---

### 4.2 Security

| ID | Requirement |
|---|---|
| NF-SEC-01 | Local SQLite database must be encrypted at rest using AES-256 |
| NF-SEC-02 | API credentials and tokens must be stored in the device's secure hardware keystore |
| NF-SEC-03 | All cloud communication must use TLS 1.2 or higher |
| NF-SEC-04 | No personally identifiable information (PII) may be stored in plaintext |
| NF-SEC-05 | The application must pass an OWASP Mobile Top 10 security checklist before production release |

---

### 4.3 Reliability

| ID | Requirement |
|---|---|
| NF-REL-01 | The app must not lose any transaction data in the event of an unexpected process termination |
| NF-REL-02 | The sync engine must successfully retry failed uploads with no data loss |
| NF-REL-03 | The cloud backend must target 99.5% uptime (SLA) |

---

### 4.4 Usability

| ID | Requirement |
|---|---|
| NF-USE-01 | The mobile UI must be operable by a field agent with one hand |
| NF-USE-02 | All primary workflows (create transaction, capture photo, voice input) must be reachable within 3 taps from the home screen |
| NF-USE-03 | The UI must support a high-contrast outdoor mode for use under direct sunlight |
| NF-USE-04 | On-screen text must meet WCAG AA contrast standards |
| NF-USE-05 | The app must support screen sizes from 5.0" to 7.0" |

---

### 4.5 Compatibility

| ID | Requirement |
|---|---|
| NF-COMP-01 | The mobile app must support Android 8.0 (API level 26) and above |
| NF-COMP-02 | The app must support devices with 2GB RAM minimum |
| NF-COMP-03 | The backend API must be compatible with common ERP REST integration patterns |

---

### 4.6 Scalability

| ID | Requirement |
|---|---|
| NF-SCALE-01 | The cloud backend must support onboarding of up to 10,000 field agents per tenant |
| NF-SCALE-02 | The sync pipeline must handle concurrent sync from 1,000 devices without degradation |

---

## 5. System Constraints

- Primary deployment environment: low-connectivity rural Africa
- Target hardware: mid-range Android devices (2–4GB RAM, no guaranteed cellular data)
- AI models must fit within 50MB total on-device storage allocation
- The platform must not require Google Play Services for core functionality
- Battery impact must be minimized — no continuous background polling; use connectivity change events instead

---

## 6. Acceptance Criteria Summary (by Phase)

### Phase 1 — Local Data Engine
- [ ] Field agent can create, view, and edit a transaction record completely offline
- [ ] All transactions are persisted to encrypted local SQLite storage
- [ ] App passes basic UI/UX usability test on a 5" Android device in outdoor conditions

### Phase 2 — AI Compression & Quantization
- [ ] Voice transcription works offline in Hausa, Igbo, Yoruba, and Pidgin
- [ ] Speech-to-text latency < 3 seconds on target hardware
- [ ] INT8 quantized image classification model deployed and operational on-device
- [ ] AI models total < 50MB on-device storage

### Phase 3 — Sync & ERP Integration
- [ ] Background sync engine triggers automatically on connectivity restore
- [ ] Hash integrity verified end-to-end across device and cloud
- [ ] REST API available for ERP pull integration
- [ ] Integrity mismatch alert delivered to admin within 60 seconds of sync

### Phase 4 — Enterprise Deployment
- [ ] RBAC fully enforced across all roles
- [ ] Reporting dashboard operational for Cooperative Manager role
- [ ] Fraud alert count visible in dashboard
- [ ] CSV/PDF export functional for transaction reports
- [ ] Platform passes OWASP Mobile Top 10 audit

---

## 7. Out of Scope (v1.0)

The following are noted for future releases and are explicitly excluded from v1.0:

- Blockchain audit trail
- Satellite connectivity fallback (e.g., Starlink)
- AI quality grading (grade A/B/C scoring)
- QR/NFC commodity tagging
- Biometric field agent verification
- Real-time fraud scoring engine

---

## 8. Open Questions

| # | Question | Owner |
|---|---|---|
| 1 | Which ERP systems must be supported at launch (SAP, Odoo, custom)? | Product |
| 2 | What is the maximum on-device storage budget for AI models? | Engineering |
| 3 | Are there data residency requirements for cloud storage of transaction records? | Legal/Compliance |
| 4 | Which African languages beyond the listed four are required for v1? | Product |
| 5 | Is iOS support required at any phase? | Product |
