# HyperLocal Testing Portal — API Mapping Specification

This document maps the custom Testing Portal REST and SSE endpoints implemented inside `server.py` to their target simulation action, payload formats, and events.

---

## 1. REST Endpoints (GET)

All GET endpoints return a JSON wrapper in the format `{"data": ...}`.

| Endpoint | Description | Return Payload Structure |
|---|---|---|
| `GET /api/portal/dashboard` | Returns current counts of branches, shops, categories, active users, online riders, pending orders, and simulated revenue. | `{"data": {"totalOrders": 12, "pendingOrders": 1, ...}}` |
| `GET /api/portal/db-snapshot` | Returns the entire, raw `database.json` contents. Used by the Database Inspector. | `{"data": { "config": {...}, "user": {...}, "branches": {...} }}` |
| `GET /api/portal/config` | Returns the `config` block of the mock database. | `{"data": { "maintenanceMode": false, "appVersion": "2.4.12", ... }}` |
| `GET /api/portal/orders` | Returns a list of all orders. | `{"data": [{"id": "HL-1234", "status": "PENDING", ...}]}` |
| `GET /api/portal/users` | Returns all registered users from `database.json`. | `{"data": [{"email": "user@example.com", "name": "...", "status": "ACTIVE"}]}` |
| `GET /api/portal/banners` | Returns home promotion banners. | `{"data": [{"id": "...", "imageUrl": "...", "isActive": true}]}` |
| `GET /api/portal/offers` | Returns active coupon codes, discounts, BOGO offers. | `{"data": [{"id": "...", "code": "SAVE10", "isActive": true}]}` |
| `GET /api/portal/notifications` | Returns history log of sent push notifications. | `{"data": [{"id": "...", "title": "...", "sentAt": "..."}]}` |

---

## 2. REST Endpoints (POST)

All POST endpoints require a `Content-Type: application/json` header and return `{"success": true, "data": ...}`.

### Branches
- **Create**: `POST /api/portal/branches/create`
  - Payload: `{"name": "Deli Branch", "address": "...", "latitude": 37.77, "longitude": -122.41, "servingRadiusKm": 5.0, "deliveryFee": 2.5}`
- **Update**: `POST /api/portal/branches/update`
  - Payload: `{"id": "branch-a", "isOpen": false, "servingRadiusKm": 8.0}`
- **Delete**: `POST /api/portal/branches/delete`
  - Payload: `{"id": "branch-id"}`

### Shops
- **Create**: `POST /api/portal/shops/create`
  - Payload: `{"name": "SuperMart", "isOpen": true, "rating": 4.8}`
- **Toggle Open/Closed**: `POST /api/portal/shops/toggle`
  - Payload: `{"id": "shop-id"}`
- **Delete**: `POST /api/portal/shops/delete`
  - Payload: `{"id": "shop-id"}`

### Categories & Products
- **Create Category**: `POST /api/portal/categories/create`
  - Payload: `{"label": "Grocery", "iconUrl": "🛒", "displayOrder": 1}`
- **Create Product**: `POST /api/portal/products/create`
  - Payload: `{"name": "Organic Milk", "price": 4.5, "stock": 100, "categoryId": "grocery"}`
- **Adjust Stock**: `POST /api/portal/inventory/adjust`
  - Payload: `{"productId": "milk-id", "delta": -10}` (or `{"productId": "...", "setTo": 0}`)

### Orders & Payments
- **Create Test Order**: `POST /api/portal/orders/create-test`
  - Payload: `{"totalPrice": 45.0, "deliveryFee": 2.5, "items": [...]}`
- **Advance Status**: `POST /api/portal/orders/advance-status`
  - Payload: `{"orderId": "HL-1234", "status": "PREPARING", "remarks": "Kitchen confirmed"}`
- **Inject Payment Result**: `POST /api/portal/payment/inject`
  - Payload: `{"orderId": "HL-1234", "result": "SUCCESS"}`

---

## 3. Server-Sent Events (SSE) Stream

### Connection
- **Endpoint**: `GET /api/portal/events`
- **Headers**: `Content-Type: text/event-stream`, `Cache-Control: no-cache`

### Live Event Format
The server emits chunked text lines starting with `data: `, containing a JSON object:
```json
{
  "id": "a1b2c3d4",
  "type": "ORDER",
  "action": "STATUS_UPDATE",
  "payload": {
    "orderId": "HL-1234",
    "status": "IN_TRANSIT"
  },
  "ts": "2026-07-03T10:00:00Z"
}
```

The portal streams these events into the **Live Event Monitor** and logs them dynamically.
