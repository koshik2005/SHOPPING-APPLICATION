# WEB PORTAL ARCHITECTURE
## HyperLocal Enterprise Portal — Single Permission-Driven Application

**Version:** 2.0  
**URL:** http://localhost:4000 (dev) | https://portal.hyperlocal.app (prod)

---

## 1. Design Philosophy

> **One portal. Every role. Permission-controlled modules.**

The enterprise portal is a **single React application** where the visible modules are determined entirely by the authenticated user's roles and permissions. There are no separate applications for Branch Manager vs SUPER_ADMIN — the same codebase renders the appropriate interface.

---

## 2. Technology Stack

| Layer | Technology |
|---|---|
| Framework | React 18 + TypeScript + Vite |
| UI Library | Material UI v6 (Dark enterprise theme) |
| State / Data | TanStack React Query v5 |
| Routing | React Router v7 |
| Forms | React Hook Form + Zod validation |
| Maps | Leaflet + react-leaflet |
| Charts | Recharts |
| Auth Client | Axios with JWT interceptor + auto-refresh |
| Real-time | EventSource (SSE) |

---

## 3. Application Structure

```
enterprise-portal/
  src/
    auth/
      AuthContext.tsx         ← React context: user, roles, tokens
      useAuth.ts              ← hook: login, logout, refresh, hasRole
      LoginPage.tsx           ← Email/Password, Google OAuth, OTP flows
      OtpVerifyPage.tsx       ← OTP input step
      ProtectedRoute.tsx      ← route guard component
    api/
      client.ts               ← axios instance with JWT interceptor
      auth.ts                 ← auth API calls
      branches.ts, shops.ts, products.ts, orders.ts... (per domain)
    components/
      Layout.tsx              ← sidebar + header (permission-aware)
      PermissionGuard.tsx     ← <PermissionGuard require="orders:write">
      StatCard.tsx
      EventLog.tsx            ← SSE live feed
      MapView.tsx             ← Leaflet wrapper
      DataTable.tsx           ← sortable/filterable MUI DataGrid
    pages/
      Dashboard.tsx
      Branches.tsx            ← BRANCH_MANAGER, SUPER_ADMIN
      Shops.tsx               ← SHOP_OWNER, BRANCH_MANAGER, SUPER_ADMIN
      Products.tsx + Categories.tsx
      Orders.tsx              ← multi-role with scoped views
      Customers.tsx           ← SUPPORT_AGENT, SUPER_ADMIN
      Delivery.tsx            ← GPS map + partner management
      Inventory.tsx           ← stock management
      Payments.tsx + Wallet.tsx
      Reports.tsx + Analytics.tsx
      Notifications.tsx       ← broadcast notifications
      Users.tsx               ← user management (SUPER_ADMIN only)
      Roles.tsx + Permissions.tsx  ← role assignment (SUPER_ADMIN only)
      AuditLogs.tsx           ← immutable log viewer (AUDITOR, QA)
      SystemSettings.tsx      ← config/feature flags (SUPER_ADMIN)
      TestingTools.tsx        ← integrated testing simulator (QA_ENGINEER only)
    theme.ts                  ← MUI dark enterprise theme
    App.tsx                   ← routes with ProtectedRoute guards
    main.tsx                  ← entry point
```

---

## 4. Authentication Flow

```
Portal opens → check localStorage for tokens
  ↓ No tokens? → redirect to /login
  ↓ Has tokens? → validate with /api/v1/auth/validate
       ↓ valid → load user context → render portal
       ↓ invalid → try refresh token
           ↓ success → store new tokens → render portal
           ↓ failure → redirect to /login

Login Page:
  Option A: Email + Password → POST /api/v1/auth/login/password
  Option B: Google OAuth     → POST /api/v1/auth/google-login
  Option C: OTP via Email    → POST /api/v1/auth/send-otp
                             → POST /api/v1/auth/verify-otp
  All paths return: { accessToken, refreshToken, user { roles, branchId, shopId } }
```

### JWT Auto-Refresh Interceptor
```typescript
// api/client.ts
axios.interceptors.response.use(
  (response) => response,
  async (error) => {
    if (error.response?.status === 401 && !error.config._retry) {
      error.config._retry = true;
      const newToken = await refreshAccessToken();
      error.config.headers['Authorization'] = `Bearer ${newToken}`;
      return axios(error.config);
    }
    return Promise.reject(error);
  }
);
```

---

## 5. Permission-Aware Navigation

```typescript
// Layout.tsx — sidebar renders only accessible modules
const SIDEBAR_MODULES = [
  { path: '/dashboard',        label: 'Dashboard',        icon: <DashboardIcon />, roles: ['ALL'] },
  { path: '/branches',         label: 'Branches',         icon: <LocationIcon />,  roles: ['SUPER_ADMIN','SYSTEM_ADMIN','REGIONAL_MANAGER','BRANCH_MANAGER'] },
  { path: '/shops',            label: 'Shops',            icon: <StoreIcon />,     roles: ['SUPER_ADMIN','BRANCH_MANAGER','SHOP_OWNER','SHOP_MANAGER'] },
  { path: '/products',         label: 'Products',         icon: <InventoryIcon />, roles: ['SUPER_ADMIN','BRANCH_MANAGER','SHOP_OWNER','SHOP_MANAGER'] },
  { path: '/orders',           label: 'Orders',           icon: <OrderIcon />,     roles: ['SUPER_ADMIN','BRANCH_MANAGER','SHOP_OWNER','SUPPORT_AGENT','FINANCE'] },
  { path: '/customers',        label: 'Customers',        icon: <PeopleIcon />,    roles: ['SUPER_ADMIN','SYSTEM_ADMIN','SUPPORT_AGENT'] },
  { path: '/delivery',         label: 'Delivery',         icon: <DeliveryIcon />,  roles: ['SUPER_ADMIN','BRANCH_MANAGER'] },
  { path: '/inventory',        label: 'Inventory',        icon: <BoxIcon />,       roles: ['SUPER_ADMIN','BRANCH_MANAGER','SHOP_OWNER'] },
  { path: '/payments',         label: 'Payments',         icon: <PaymentIcon />,   roles: ['SUPER_ADMIN','FINANCE','SUPPORT_AGENT'] },
  { path: '/wallet',           label: 'Wallet',           icon: <WalletIcon />,    roles: ['SUPER_ADMIN','FINANCE','SUPPORT_AGENT'] },
  { path: '/reports',          label: 'Reports',          icon: <ReportIcon />,    roles: ['SUPER_ADMIN','FINANCE','BRANCH_MANAGER','SHOP_OWNER'] },
  { path: '/analytics',        label: 'Analytics',        icon: <AnalyticsIcon />, roles: ['SUPER_ADMIN','FINANCE','REGIONAL_MANAGER'] },
  { path: '/notifications',    label: 'Notifications',    icon: <BellIcon />,      roles: ['SUPER_ADMIN','BRANCH_MANAGER'] },
  { path: '/users',            label: 'Users',            icon: <AdminIcon />,     roles: ['SUPER_ADMIN','SYSTEM_ADMIN'] },
  { path: '/roles',            label: 'Roles & Permissions', icon: <ShieldIcon />, roles: ['SUPER_ADMIN'] },
  { path: '/audit-logs',       label: 'Audit Logs',       icon: <LogIcon />,       roles: ['SUPER_ADMIN','AUDITOR','QA_ENGINEER'] },
  { path: '/system-settings',  label: 'System Settings',  icon: <SettingsIcon />,  roles: ['SUPER_ADMIN','SYSTEM_ADMIN'] },
  { path: '/testing-tools',    label: 'Testing Tools',    icon: <BugIcon />,       roles: ['SUPER_ADMIN','QA_ENGINEER'] },
];

// Filter visible modules by current user's roles
const visibleModules = SIDEBAR_MODULES.filter(mod =>
  mod.roles.includes('ALL') ||
  mod.roles.some(r => user.roles.includes(`ROLE_${r}`))
);
```

---

## 6. PermissionGuard Component

```typescript
// components/PermissionGuard.tsx
interface PermissionGuardProps {
  require: string;      // e.g. "orders:write"
  fallback?: ReactNode; // shown when permission denied
  children: ReactNode;
}

export function PermissionGuard({ require, fallback, children }: PermissionGuardProps) {
  const { can } = useAuth();
  if (!can(require)) {
    return fallback ? <>{fallback}</> : (
      <Alert severity="error">
        You do not have permission to access this feature.
      </Alert>
    );
  }
  return <>{children}</>;
}

// Usage in pages:
<PermissionGuard require="branches:write">
  <Button onClick={openCreateDialog}>New Branch</Button>
</PermissionGuard>
```

---

## 7. Testing Tools Integration (QA_ENGINEER Module)

The `TestingTools` page (`/testing-tools`) is the **integrated version of the previous testing portal**:
- Only visible to `ROLE_QA_ENGINEER` and `ROLE_SUPER_ADMIN`
- Uses the same API functions from the previous `testing-portal/src/api/portal.ts`
- The standalone `testing-portal/` Vite app remains operational as a separate dev tool
- In the enterprise portal it is a module within the single-SPA

---

## 8. Build & Deployment

```bash
# Development
cd enterprise-portal
npm run dev   # starts at http://localhost:4000

# Production build
npm run build
# Output: enterprise-portal/dist/
# Served by Nginx container in docker-compose
```

### Docker Compose Service
```yaml
enterprise-portal:
  build:
    context: ./enterprise-portal
    dockerfile: Dockerfile
  container_name: hyperlocal-enterprise-portal
  ports:
    - "4000:80"   # Nginx serves the built React app
  networks:
    - hyperlocal-network
  environment:
    VITE_API_BASE_URL: http://localhost:8080
```
