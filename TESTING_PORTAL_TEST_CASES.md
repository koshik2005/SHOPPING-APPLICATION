# HyperLocal Testing Portal — Test Cases

This document outlines key verification test suites to run using the HyperLocal Testing Portal to audit the Customer App's real-time synchronization.

---

## TC-01: Maintenance Mode Cutoff
- **Objective**: Verify that activating Maintenance Mode blocks all customer interactions.
- **Steps**:
  1. Open the Customer Flutter App on the welcome or home screen.
  2. In the testing portal, navigate to the **Config** module.
  3. Toggle **Maintenance Mode** to `ON` and click Save.
  4. Observe the Customer App.
- **Expected Outcome**: The Customer App instantly overlays a full-screen blocking "Maintenance in Progress" screen. Toggle off allows immediate recovery back to home.

---

## TC-02: Instant Wallet Sync
- **Objective**: Verify that manual wallet adjustments sync immediately without requiring app restarts.
- **Steps**:
  1. Open the Customer App and go to the Wallet page. Note the balance.
  2. In the portal, open the **Wallet** module.
  3. Enter `$50.00`, choose **CREDIT**, and click Apply.
  4. Inspect the Customer App Wallet screen.
- **Expected Outcome**: The Customer App wallet screen reflects the additional `$50.00` immediately.

---

## TC-03: Out-of-Stock Checkout Block
- **Objective**: Verify that items set to 0 stock cannot be ordered by customers.
- **Steps**:
  1. Find a product in the Customer App (e.g., "Tablet").
  2. In the portal, open the **Inventory** module.
  3. Find the product and click the **OOS** button (sets stock to 0).
  4. Inspect the product page in the Customer App.
- **Expected Outcome**: The product card in the Customer App shows an "Out of Stock" banner and the "Add to Cart" button is disabled.

---

## TC-04: Order Lifecycle Map Tracking
- **Objective**: Verify order status tracking and live map synchronization.
- **Steps**:
  1. Add items to cart and check out in the Customer App. Note the Order ID.
  2. In the portal, open **Orders**. Find the new Order ID.
  3. Click **→ ACCEPTED**, then **→ PREPARING**, then **→ PACKED**, and **→ READY**.
  4. Verify that the Customer App's timeline highlights update with matching status.
  5. Click **→ IN_TRANSIT**. Go to the **Delivery** module.
  6. Drag the assigned rider marker on the Leaflet map.
- **Expected Outcome**: The Customer App displays the live tracking map. As you drag the marker in the portal, the rider's icon updates smoothly in the Flutter app in real-time.
