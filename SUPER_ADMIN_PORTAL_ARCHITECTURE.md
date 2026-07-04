# HyperLocal Enterprise Super Admin Portal — Architecture Specification
**Version:** 2.0

---

## 1. Architectural Philosophy

The HyperLocal Enterprise Control Center is a **Single-Page Application (SPA)** written in React 19, TypeScript, and Vite. Rather than maintaining multiple distinct web apps for different operational roles, it runs as a unified console where available modules are dynamically loaded and rendered based on the client’s authenticated permissions.

### Core Architecture Goals
- **Single Source of Truth**: Unified component registry, API client, and authentication context.
- **Client-Side Authorization (Zero Trust)**: Views are conditionally rendered, but the backend API remains the final gatekeeper for data operations.
- **Dynamic Module Loading**: Lazy loading and code splitting ensure high speed, especially on remote 3G/4G branch networks.
- **Real-Time Integration**: Uses Server-Sent Events (SSE) and WebSockets for live order tickers and rider location tracks.

---

## 2. Technical Stack Layout

```
╔══════════════════════════════════════════════════════════════════════╗
║                          React 19 Core SPA                           ║
║  ┌────────────────────────────────────────────────────────────────┐  ║
║  │                     Authentication Context                     │  ║
║  │        - JWT Token Management      - Session Tracking          │  ║
║  │        - Permission Evaluation     - Oauth / Google login      │  ║
║  └───────────────────────┬────────────────────────────────────────┘  ║
║                          │                                           ║
║                          ▼                                           ║
║  ┌────────────────────────────────────────────────────────────────┐  ║
║  │                      Dynamic Layout Shell                      │  ║
║  │           - Collapsible Sidebar      - Breadcrumb Navigation   │  ║
║  │           - Notification Drawer      - Global Search bar       │  ║
║  └───────────────────────┬────────────────────────────────────────┘  ║
║                          │                                           ║
║       ┌──────────────────┼───────────────────┬────────────────┐      ║
║       ▼                  ▼                   ▼                ▼      ║
║  ┌───────────┐     ┌───────────┐       ┌───────────┐    ┌──────────┐ ║
║  │ Dashboard │     │ Operations│       │ Financial │    │ QA Tools │ ║
║  │ Recharts  │     │ OSM Maps  │       │ Ledger    │    │ Simulator│ ║
║  └───────────┘     └───────────┘       └───────────┘    └──────────┘ ║
║                                                                      ║
╚═══════════════════════════════╤══════════════════════════════════════╝
                                │ Axios Client with JWT
                                ▼
╔══════════════════════════════════════════════════════════════════════╗
║                         API GATEWAY (:8080)                          ║
║     - JWT Verification               - Sliding Window Limiting       ║
║     - Correlation ID Injection       - Service-Prefix Router         ║
╚══════════════════════════════════════════════════════════════════════╝
```

---

## 3. Directory Layout Blueprint

```
enterprise-portal/
├── src/
│   ├── api/
│   │   ├── client.ts             # Axios interceptor with token refresh
│   │   └── portal.ts             # Core backend mapping functions
│   ├── auth/
│   │   ├── AuthContext.tsx       # Auth provider mapping roles to scopes
│   │   ├── useAuth.ts            # Custom context access hook
│   │   ├── LoginPage.tsx         # Multi-method login screen
│   │   └── ProtectedRoute.tsx    # Role & Permission route guard
│   ├── components/
│   │   ├── Layout.tsx            # Sidebar shell utilizing permissions
│   │   ├── PermissionGuard.tsx   # Inline component-level visibility guard
│   │   ├── EventLog.tsx          # Real-time SSE listener output
│   │   └── MapView.tsx           # Leaflet/OpenStreetMap wrapper
│   ├── pages/
│   │   ├── Dashboard.tsx         # Primary system metrics dashboard
│   │   ├── UserManagement.tsx    # User list, CRUD, suspend, session kill
│   │   ├── RbacManagement.tsx    # Role templates & matrix configuration
│   │   ├── BranchManagement.tsx  # Branch geofencing and logistics settings
│   │   ├── DeliveryManagement.tsx # KYC files & live rider heatmaps
│   │   ├── WalletFinance.tsx     # Settlements ledger & tax statements
│   │   ├── SupportCenter.tsx     # Tickets, chats, and FAQs manager
│   │   ├── SystemConfig.tsx      # Currencies, SMTP, & maintenance flag
│   │   ├── SystemMonitor.tsx     # Health checks of servers & microservices
│   │   └── TestingTools.tsx      # Multi-module QA simulator panels
│   ├── theme.ts                  # Material UI dark/light theme definitions
│   ├── App.tsx                   # Central router & protected route lists
│   └── main.tsx                  # StrictMode entrypoint
├── index.html
├── vite.config.ts
└── package.json
```

---

## 4. User Session and State Retention

User metadata, including `accessToken`, `refreshToken`, `sessionId`, and profile details, are handled in browser local storage:

- **Access Token**: Set in memory/sessionStorage (refreshed automatically when expired via Axios response interceptors).
- **Refresh Token**: Stored securely to request new access tokens on expiry without force-logging out users.
- **Session Registry**: Auth service monitors active sessions in Redis, enabling Super Admins to perform remote logouts.
