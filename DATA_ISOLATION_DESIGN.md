# DATA ISOLATION DESIGN
## HyperLocal Enterprise Platform — Tenant-Aware Data Scoping

**Version:** 2.0

---

## 1. Isolation Principle

> **Data isolation is enforced at three layers: Gateway (JWT claims), Service (AuthContext), Repository (query scoping). No single layer is trusted alone.**

The platform uses a **hybrid multi-tenant model**:
- All tenants share the same database schemas
- Row-level isolation is enforced in application logic (service + repository layer)
- PostgreSQL Row Level Security (RLS) provides a database-level backstop for critical tables

---

## 2. Tenant Dimensions

Every user account carries scoping context:

```
User {
  userId:   UUID    → identifies the individual
  roles:    Set<String>  → determines access level
  branchId: UUID?   → non-null for BRANCH_MANAGER, REGIONAL_MANAGER
  shopId:   UUID?   → non-null for SHOP_OWNER, SHOP_MANAGER
}
```

This context is extracted from the JWT at the gateway, injected as HTTP headers, and populated into the request-scoped `AuthContext` thread-local in each service.

---

## 3. AuthContext Implementation

### `AuthContext.java` (hyperlocal-common)
```java
public class AuthContext {
    private static final ThreadLocal<AuthContextData> holder = new ThreadLocal<>();

    public static void set(AuthContextData ctx) { holder.set(ctx); }
    public static AuthContextData get() { return holder.get(); }
    public static void clear() { holder.remove(); }

    public static UUID requireUserId() {
        return Optional.ofNullable(get())
            .map(AuthContextData::userId)
            .orElseThrow(() -> new UnauthorizedException("No authenticated context"));
    }

    public static UUID requireBranchId() {
        return Optional.ofNullable(get())
            .map(AuthContextData::branchId)
            .orElseThrow(() -> new ForbiddenException("No branch scope in token"));
    }

    public record AuthContextData(
        UUID userId,
        Set<String> roles,
        UUID branchId,    // null if user is not branch-scoped
        UUID shopId,      // null if user is not shop-scoped
        String sessionId,
        String correlationId
    ) {
        public boolean hasRole(String role) { return roles.contains(role); }
        public boolean isSuperAdmin() { return roles.contains("ROLE_SUPER_ADMIN"); }
    }
}
```

### `AuthContextFilter.java` (hyperlocal-common)
```java
@Component
public class AuthContextFilter extends OncePerRequestFilter {
    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain chain) throws IOException, ServletException {
        try {
            String userId = request.getHeader("X-User-Id");
            String roles  = request.getHeader("X-User-Roles");
            String branchId = request.getHeader("X-Branch-Id");
            String shopId   = request.getHeader("X-Shop-Id");
            String sessionId = request.getHeader("X-Session-Id");
            String correlationId = request.getHeader("X-Correlation-ID");

            if (userId != null) {
                AuthContext.set(new AuthContext.AuthContextData(
                    UUID.fromString(userId),
                    parseRoles(roles),
                    branchId != null ? UUID.fromString(branchId) : null,
                    shopId != null ? UUID.fromString(shopId) : null,
                    sessionId,
                    correlationId
                ));
            }
            chain.doFilter(request, response);
        } finally {
            AuthContext.clear(); // Critical: prevent thread-local leaks
        }
    }
}
```

---

## 4. Isolation Rules Per Entity

### 4.1 Products & Inventory
```java
// SUPER_ADMIN / SYSTEM_ADMIN: no filter
// BRANCH_MANAGER: all products in shops within their branch
// SHOP_OWNER: only products in their shop
// CUSTOMER: only available (non-deleted, in-stock) products

@Transactional(readOnly = true)
public List<ProductDto> getProducts() {
    AuthContext.AuthContextData ctx = AuthContext.get();

    if (ctx.isSuperAdmin() || ctx.hasRole("ROLE_SYSTEM_ADMIN")) {
        return productRepository.findByDeletedFalse();
    }
    if (ctx.hasRole("ROLE_SHOP_OWNER") || ctx.hasRole("ROLE_SHOP_MANAGER")) {
        return productRepository.findByShopIdAndDeletedFalse(ctx.shopId());
    }
    if (ctx.hasRole("ROLE_BRANCH_MANAGER")) {
        return productRepository.findByBranchIdAndDeletedFalse(ctx.branchId());
    }
    // CUSTOMER, DELIVERY_PARTNER: only public-facing available products
    return productRepository.findByIsAvailableTrueAndDeletedFalse();
}
```

### 4.2 Orders
```java
// BRANCH_MANAGER: orders where order.branchId == ctx.branchId
// SHOP_OWNER: orders where order.shopId == ctx.shopId
// DELIVERY_PARTNER: orders assigned to them
// CUSTOMER: only their own orders

public Page<OrderSummary> getOrders(Pageable pageable) {
    AuthContext.AuthContextData ctx = AuthContext.get();

    if (ctx.isSuperAdmin() || ctx.hasRole("ROLE_SYSTEM_ADMIN")) {
        return orderRepository.findAll(pageable);
    }
    if (ctx.hasRole("ROLE_BRANCH_MANAGER")) {
        return orderRepository.findByBranchId(ctx.branchId(), pageable);
    }
    if (ctx.hasRole("ROLE_SHOP_OWNER")) {
        return orderRepository.findByShopId(ctx.shopId(), pageable);
    }
    if (ctx.hasRole("ROLE_DELIVERY_PARTNER")) {
        return orderRepository.findByAssignedPartnerId(ctx.userId(), pageable);
    }
    // CUSTOMER: own orders only
    return orderRepository.findByCustomerId(ctx.userId(), pageable);
}
```

### 4.3 Wallet
```java
// Only the wallet owner OR admins/finance can access
public WalletDto getWallet(UUID walletId) {
    AuthContext.AuthContextData ctx = AuthContext.get();
    WalletEntity wallet = walletRepository.findById(walletId)
        .orElseThrow(() -> new ResourceNotFoundException("Wallet not found"));

    // Enforce ownership: customer can only see own wallet
    if (!ctx.isSuperAdmin()
        && !ctx.hasRole("ROLE_FINANCE")
        && !ctx.hasRole("ROLE_SUPPORT_AGENT")
        && !wallet.getUserId().equals(ctx.userId())) {
        throw new ForbiddenException("Access denied to wallet");
    }
    return mapToDto(wallet);
}
```

### 4.4 Delivery Partner Location
```java
// Only the partner themselves can post their location
public void updateLocation(UUID deliveryId, LocationUpdate update) {
    DeliveryEntity delivery = deliveryRepository.findById(deliveryId)
        .orElseThrow(() -> new ResourceNotFoundException("Delivery not found"));

    if (!delivery.getPartnerId().equals(AuthContext.requireUserId())) {
        throw new ForbiddenException("Cannot update location for another partner's delivery");
    }
    delivery.setCurrentLocation(update.toPoint());
    deliveryRepository.save(delivery);
}
```

---

## 5. PostgreSQL Row Level Security (Critical Tables)

Applied as a database-level safety net for the most sensitive tables:

```sql
-- Enable RLS on wallets table
ALTER TABLE wallets ENABLE ROW LEVEL SECURITY;

-- Policy: application user can only see rows matching current_setting
CREATE POLICY wallet_isolation ON wallets
    USING (user_id = current_setting('app.current_user_id')::uuid);

-- Set app context in each request (called by service before any query)
SET LOCAL app.current_user_id = '550e8400-e29b-41d4-a716-446655440000';
```

> [!NOTE]
> RLS policies are enforced for the `hyperlocal_app_user` database role. The admin migration role bypasses RLS for schema changes only.

---

## 6. IDOR Prevention

Every resource access must verify ownership, not just existence:

```java
// ❌ WRONG — trusts the URL parameter directly
public OrderDto getOrder(UUID orderId) {
    return orderRepository.findById(orderId)
        .map(this::mapToDto)
        .orElseThrow(...);
}

// ✅ CORRECT — verifies caller has scope
public OrderDto getOrder(UUID orderId) {
    OrderEntity order = orderRepository.findById(orderId)
        .orElseThrow(() -> new ResourceNotFoundException("Order not found"));

    AuthContext.AuthContextData ctx = AuthContext.get();
    boolean isOwner     = order.getCustomerId().equals(ctx.userId());
    boolean isBranchMgr = ctx.hasRole("ROLE_BRANCH_MANAGER")
                          && order.getBranchId().equals(ctx.branchId());
    boolean isAdmin     = ctx.isSuperAdmin() || ctx.hasRole("ROLE_SYSTEM_ADMIN");

    if (!isOwner && !isBranchMgr && !isAdmin) {
        throw new ForbiddenException("Access denied");
    }
    return mapToDto(order);
}
```

---

## 7. Data Isolation Test Matrix

| Test Case | Actor | Action | Expected Result |
|---|---|---|---|
| Customer reads own order | CUSTOMER userId=A | `GET /orders/{orderId of A}` | ✅ 200 OK |
| Customer reads another's order | CUSTOMER userId=A | `GET /orders/{orderId of B}` | ❌ 403 Forbidden |
| Branch Manager reads own branch orders | BRANCH_MGR branchId=B1 | `GET /orders?branchId=B1` | ✅ 200 OK |
| Branch Manager reads other branch | BRANCH_MGR branchId=B1 | `GET /orders?branchId=B2` | ❌ 403 Forbidden |
| Shop Owner reads own products | SHOP_OWNER shopId=S1 | `GET /inventory/products?shopId=S1` | ✅ 200 OK |
| Shop Owner updates another shop's product | SHOP_OWNER shopId=S1 | `PUT /inventory/products/{S2_product_id}` | ❌ 403 Forbidden |
| Delivery Partner posts location | DELIVERY_PARTNER partnerId=D1 | `POST /deliveries/{D1_delivery}/location` | ✅ 200 OK |
| Delivery Partner posts for another | DELIVERY_PARTNER partnerId=D1 | `POST /deliveries/{D2_delivery}/location` | ❌ 403 Forbidden |
