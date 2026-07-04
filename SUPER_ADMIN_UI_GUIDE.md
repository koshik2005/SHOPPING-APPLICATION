# HyperLocal Enterprise Portal — UI/UX Guide
**Version:** 2.0

---

## 1. UI Design Principles

The portal interface is built for efficiency, security, and responsiveness using **Material UI (MUI v6)**.

### Themes & Layout
- **Visual Palette**: Curated dark theme palette matching premium design directives:
  - Background (Default): `#121212` (pure charcoal)
  - Card Surfaces: `#1e1e1e` (elevated grey)
  - Primary Accent: `#bb86fc` (neon purple)
  - Secondary Accent: `#03dac6` (teal green)
- **Responsive Layout**: Designed with standard grid spacing. Automatically collapses sidebar navigation on tablet and mobile viewports.
- **Micro-Animations**: Hover animations on dashboard cards and status triggers enhance the premium feel.

---

## 2. Shell Controls & Toolbar

The layout shell consists of three primary areas:

```
┌────────────────────────────────────────────────────────┐
│  Toolbar (Global Search │ Notifications │ User Avatar) │
├──────────────┬─────────────────────────────────────────┤
│ Sidebar      │ Workspace Area                          │
│ (Collapsible)│                                         │
│              │                                         │
│              │                                         │
│              │                                         │
└──────────────┴─────────────────────────────────────────┘
```

- **Collapsible Sidebar**: Renders list items matching the user's explicit roles. Can be collapsed to narrow icon-only status.
- **Quick Action Menu**: Triggered from user avatar dropdown, providing direct access to Profile Settings and Sign Out.

---

## 3. Key Operational Views

### 3.1 Enterprise Dashboard
- Displays system status cards with metrics (Branches, Shops, Orders, Earnings).
- Embedded chart layouts for daily orders and weekly earnings tracking.
- Live microservice health logs monitoring endpoints on startup.

### 3.2 User & Profile Inspector
- Unified users table with filters for role and account status.
- Interactive actions to trigger suspension updates, reset credentials, or terminate sessions.

### 3.3 Logistics Geofencing Map (Leaflet)
- Active map rendering for branch operational boundaries.
- Support for dragging coordinates to adjust branches coordinates and display serving radius circles.

### 3.4 Live SSE Ticker (Monitor)
- Connects to `/api/portal/events` streaming direct event logs.
- Displays incoming event payload data tree.
