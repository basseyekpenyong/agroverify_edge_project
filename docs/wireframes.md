# AgroVerify Edge — Mobile UI/UX Wireframes

**Version:** 1.0  
**Constraint:** Outdoor-optimized · One-hand operable · All primary flows ≤ 3 taps from Home

---

## Design Principles

| Principle | Implementation |
|---|---|
| Outdoor readability | Min 18sp body text, high-contrast green/white palette, no thin fonts |
| One-hand operation | All primary CTAs in bottom 40% of screen (thumb zone) |
| 3-tap rule | Home → New Transaction → Save = 2 taps |
| Offline-first | Connectivity status always visible; no action blocked by lack of network |
| Low-literacy support | Icon + label on every action, no icon-only buttons |

---

## Screen 1 — Login / PIN Entry

```
┌─────────────────────────────┐
│                             │
│                             │
│         🌱 (72px)           │
│                             │
│     AgroVerify Edge         │  ← Bold, 24sp, primary green
│   Enter PIN to continue     │  ← 14sp, grey
│                             │
│  ┌───────────────────────┐  │
│  │      ● ● ● ●         │  │  ← PIN field, 24sp, centered
│  └───────────────────────┘  │
│                             │
│  ┌───────────────────────┐  │
│  │      SIGN IN          │  │  ← Full-width, 52px tall, green
│  └───────────────────────┘  │
│                             │
│                             │
└─────────────────────────────┘
```

**Interactions:**
- Numeric keyboard auto-opens on screen load
- PIN dots fill left-to-right as digits entered
- SIGN IN button activates after 4+ digits
- Wrong PIN: field shakes, clears, shows "Invalid PIN" in red
- Loading state: spinner replaces button label

---

## Screen 2 — Home Dashboard

```
┌─────────────────────────────┐
│ AgroVerify Edge    [logout] │  ← AppBar, green bg
├─────────────────────────────┤
│ 📶 Offline — data saved     │  ← Connectivity banner, amber
│    locally                  │
├─────────────────────────────┤
│ Hello, Emeka Okafor         │  ← 20sp bold
│ Kano North Region           │  ← 13sp grey
│                             │
│ ┌─────────────┐ ┌─────────┐ │
│ │ ⚠  Pending  │ │ 📋 Today│ │  ← Stat cards
│ │     3       │ │    7    │ │
│ │  Sync       │ │ Txns    │ │
│ └─────────────┘ └─────────┘ │
│                             │
│ ┌─────────────────────────┐ │
│ │  +  NEW TRANSACTION     │ │  ← Primary CTA, 64px tall, green
│ └─────────────────────────┘ │
│                             │
│ ┌─────────────────────────┐ │
│ │  ☰  VIEW TRANSACTIONS   │ │  ← Secondary, outlined
│ └─────────────────────────┘ │
│                             │
├─────────────────────────────┤
│ 🏠 Home │ 📋 Txns │ 🔄 Sync │ ⚙ │  ← Bottom nav
└─────────────────────────────┘
```

**Interactions:**
- Connectivity banner taps to Sync Dashboard
- Stat cards are non-interactive (display only)
- NEW TRANSACTION → Screen 3 (1 tap)
- VIEW TRANSACTIONS → Screen 5 (1 tap)

---

## Screen 3 — New Transaction Form

```
┌─────────────────────────────┐
│ ← New Transaction           │  ← AppBar, green
├─────────────────────────────┤
│ 📍 GPS: 11.9987°, 8.5211°  │  ← GPS indicator, green when locked
│    ±12m accuracy            │
├─────────────────────────────┤
│ Commodity Type              │
│ ┌─────────────────────────┐ │
│ │ Maize               ▼  │ │  ← Dropdown
│ └─────────────────────────┘ │
│                             │
│ Weight              Unit    │
│ ┌──────────────┐ ┌────────┐ │
│ │ 500          │ │ kg  ▼ │ │  ← Numeric + unit dropdown
│ └──────────────┘ └────────┘ │
│                             │
│ Buyer ID / Name             │
│ ┌─────────────────────────┐ │
│ │ Alhaji Musa Danladi     │ │
│ └─────────────────────────┘ │
│                             │
│ Seller ID / Name            │
│ ┌─────────────────────────┐ │
│ │ Fatima Cooperative Ltd  │ │
│ └─────────────────────────┘ │
│                             │
│ Notes (optional)            │
│ ┌─────────────────────────┐ │
│ │                         │ │  ← 3-line text area
│ └─────────────────────────┘ │
│                             │
│ ┌─────────────────────────┐ │
│ │     SAVE TRANSACTION    │ │  ← Full-width, green, 52px
│ └─────────────────────────┘ │
└─────────────────────────────┘
```

**Interactions:**
- GPS locks automatically on screen open (spinner until locked)
- Weight field: numeric keyboard, decimal allowed
- Each text field has 🎤 mic icon on right (voice input — Phase 2)
- SAVE: validates all required fields → generates SHA-256 hash → saves to SQLite → pops to previous screen
- Unsaved changes + back button → "Discard changes?" dialog

---

## Screen 4 — Transaction Detail

```
┌─────────────────────────────┐
│ ← Transaction Detail        │  ← AppBar, green
│                        ✏   │  ← Edit icon (only if unsynced)
├─────────────────────────────┤
│ ┌─────────────────────────┐ │
│ │ Commodity    Maize      │ │
│ ├─────────────────────────┤ │
│ │ Weight       500 kg     │ │
│ ├─────────────────────────┤ │
│ │ Buyer        Alhaji...  │ │
│ ├─────────────────────────┤ │
│ │ Seller       Fatima...  │ │
│ ├─────────────────────────┤ │
│ │ Timestamp    31 May '26 │ │
│ │              14:23 UTC  │ │
│ ├─────────────────────────┤ │
│ │ GPS          11.9987°N  │ │
│ │              8.5211°E   │ │
│ ├─────────────────────────┤ │
│ │ Status       ⏳ PENDING │ │  ← amber, or ✅ SYNCED green
│ ├─────────────────────────┤ │
│ │ Hash         a3f9c2...  │ │  ← Monospace, truncated
│ └─────────────────────────┘ │
│                             │
│ [ 🖼 No images attached ]   │  ← Image section (Phase 1)
│ ┌─────────────────────────┐ │
│ │  📷  ADD PHOTO          │ │  ← Outlined button
│ └─────────────────────────┘ │
└─────────────────────────────┘
```

**Interactions:**
- Edit icon only visible if `sync_status = pending`
- Hash row: tap to copy full hash to clipboard
- Synced transactions are fully read-only (no edit icon)
- ADD PHOTO → camera capture flow (Screen 6)

---

## Screen 5 — Transaction List

```
┌─────────────────────────────┐
│ Transactions        [+ New] │  ← AppBar, green, FAB shortcut
├─────────────────────────────┤
│ 🔍 Search...                │  ← Search bar (optional)
├─────────────────────────────┤
│ ┌─────────────────────────┐ │
│ │ 🌽 Maize — 500 kg       │ │  ← Card row
│ │ 31 May 2026, 14:23      │ │
│ │                ⏳ PENDING│ │
│ └─────────────────────────┘ │
│ ┌─────────────────────────┐ │
│ │ 🥜 Groundnuts — 200 kg  │ │
│ │ 30 May 2026, 09:11      │ │
│ │                ✅ SYNCED │ │
│ └─────────────────────────┘ │
│ ┌─────────────────────────┐ │
│ │ 🌾 Sorghum — 1,000 kg   │ │
│ │ 29 May 2026, 16:45      │ │
│ │                ❌ FAILED │ │
│ └─────────────────────────┘ │
│                             │
│        [+ NEW TRANSACTION]  │  ← FAB, bottom right, green
├─────────────────────────────┤
│ 🏠 Home │ 📋 Txns │ 🔄 Sync │ ⚙ │
└─────────────────────────────┘
```

**Status badge colours:**
- PENDING → Amber
- SYNCED → Green
- FAILED → Red
- SYNCING → Blue (animated)

**Interactions:**
- Tap row → Screen 4 (Transaction Detail)
- FAB → Screen 3 (New Transaction)
- Pull-to-refresh reloads from SQLite

---

## Screen 6 — Photo Capture

```
┌─────────────────────────────┐
│ ← Add Photo                 │  ← AppBar, dark (camera mode)
├─────────────────────────────┤
│                             │
│   ┌───────────────────┐     │
│   │                   │     │
│   │   [Camera View]   │     │  ← Live camera preview
│   │                   │     │
│   └───────────────────┘     │
│                             │
│  Photo type:                │
│  [Commodity] [Scale] [Other]│  ← Chip selector
│                             │
│         📷                  │  ← Large capture button, 72px
│                             │
│  📍 GPS will be embedded    │  ← Info text, small
│     in photo metadata       │
└─────────────────────────────┘
```

**Interactions:**
- Photo type chip must be selected before capture button activates
- After capture: preview shown with Retake / Use Photo buttons
- "Use Photo" → compresses image → saves to local storage → links to transaction UUID

---

## Screen 7 — Sync Dashboard

```
┌─────────────────────────────┐
│ Sync Status                 │  ← AppBar, green
├─────────────────────────────┤
│ ┌─────────────────────────┐ │
│ │ Connectivity            │ │
│ │ 📵 Offline              │ │  ← amber when offline
│ └─────────────────────────┘ │
│                             │
│ ┌─────────────────────────┐ │
│ │ Pending Sync            │ │
│ │         3               │  ← Large number, amber
│ │ transactions waiting    │ │
│ │ Syncs automatically     │ │
│ │ when online             │ │
│ └─────────────────────────┘ │
│                             │
│ ┌─────────────────────────┐ │
│ │ Last Sync               │ │
│ │ 30 May 2026, 09:11      │ │
│ └─────────────────────────┘ │
│                             │
│ ┌─────────────────────────┐ │
│ │  🔄  SYNC NOW  (dimmed) │ │  ← Disabled when offline
│ └─────────────────────────┘ │
│                             │
│ Sync runs automatically in  │
│ background when connected.  │
├─────────────────────────────┤
│ 🏠 Home │ 📋 Txns │ 🔄 Sync │ ⚙ │
└─────────────────────────────┘
```

---

## Screen 8 — Settings

```
┌─────────────────────────────┐
│ Settings                    │  ← AppBar, green
├─────────────────────────────┤
│ ACCOUNT                     │  ← Section header, small caps
│ 👤 Emeka Okafor             │
│    field_agent · Kano North │
│                             │
│ 🏢 Cooperative              │
│    Kano Grain Cooperative   │
├─────────────────────────────┤
│ APP                         │
│ ℹ Version    1.0.0          │
│ 💾 Database  AES-256 🔒     │
├─────────────────────────────┤
│                             │
│ 🚪 Sign Out                 │  ← Red text
│                             │
├─────────────────────────────┤
│ 🏠 Home │ 📋 Txns │ 🔄 Sync │ ⚙ │
└─────────────────────────────┘
```

---

## Navigation Map

```
Login
  └── Home ──────────────────────────────────────┐
        ├── New Transaction ──→ Transaction Detail │
        ├── Transaction List ──→ Transaction Detail│
        │                         └── Add Photo   │
        ├── Sync Dashboard                        │
        └── Settings                              │
                                    Bottom Nav ───┘
```

## Tap Count Audit

| Flow | Taps from Home |
|---|---|
| Create new transaction | 1 (NEW TRANSACTION button) |
| View transaction list | 1 (VIEW TRANSACTIONS button) |
| Open sync dashboard | 1 (bottom nav) |
| View transaction detail | 2 (list → tap row) |
| Add photo to transaction | 3 (list → detail → add photo) |
| Sign out | 2 (settings → sign out) |

All primary flows ✅ within 3-tap requirement (F-OFL-05, NF-USE-02).
