# HyperLocal Testing Portal — User & Operator Guide

This guide describes how to run, navigate, and utilize the HyperLocal Testing & Simulation Portal to test the end-to-end user experience.

---

## 1. Quick Start

### Step 1: Start the API Backend
Ensure your Python mock server is running on port 8080:
```powershell
python server.py
```
This serves the mock APIs and watches `database.json`.

### Step 2: Start the Testing Portal
In a new terminal, navigate to the portal directory and launch the Vite development server:
```powershell
cd testing-portal
npm run dev
```
Open [http://localhost:3000](http://localhost:3000) in your web browser.

---

## 2. Navigating the Modules

The sidebar is divided into five core operational areas:

### A. Overview
- **Dashboard**: Live counter grid. Displays orders, active shops, categories, revenue, and delivery partners. Features a mini event stream showing the latest API log events.
- **Config**: Toggle global feature flags. You can check the `maintenanceMode` box to verify that the Customer App immediately displays a "Under Maintenance" blocking overlay.
- **Database**: Expandable interactive tree explorer. Click nodes to inspect the current state of `database.json` without opening the file manually.
- **Live Monitor**: Live streaming log console. Connects to the SSE stream and shows write operations in real-time as they happen.

### B. Commerce
- **Branches**: Create branches, edit working hours, toggle open/close status, or adjust serving geofence radiuses.
- **Shops**: Create and manage shops, set star ratings, logo/banner image URLs, and open/closed states.
- **Categories**: Add home categories with an emoji picker or adjust their display orders to test home page listing layout styles.
- **Products**: Add, edit, or delete items. Set retail prices and discount prices.
- **Inventory**: Visual stock bar sliders. Use quick buttons to adjust item count (+1, +10, -1, -5). Set item stock to 0 to simulate Out-of-Stock behavior.

### C. Transactions
- **Orders**: Create mock test orders. Step through the 8-state order lifecycle (`PENDING` → `ACCEPTED` → `PREPARING` → `PACKED` → `READY` → `PICKED_UP` → `IN_TRANSIT` → `DELIVERED`).
- **Delivery**: GPS Simulator. Select a delivery partner, then drag their rider pin on the map to trigger live location coordinates sync.
- **Wallet**: Credit or debit the user's wallet. Verify that the Customer App updates the wallet balance instantly.
- **Payments**: Select an order, select a result (SUCCESS, FAILED, TIMEOUT), and inject the payment callback to simulate payment gateway resolutions.

---

## 3. Simulating Common Test Scenarios

### Scenario A: Testing Wallet Checkout & Insufficient Funds
1. Go to the **Wallet Simulator** page.
2. Deduct the wallet balance to `$0.00` using the Debit button.
3. Attempt to place an order in the Customer Flutter App using Wallet payment.
4. Verify that the app blocks checkouts and displays an "Insufficient Wallet Balance" warning.
5. In the portal, click **Credit $100**. Verify that the Customer App instantly updates the balance and allows the checkout to proceed.

### Scenario B: Testing Rider GPS Tracking
1. Place an order in the Customer App.
2. In the portal's **Order Simulator**, advance the status to `IN_TRANSIT`.
3. Go to the **Delivery Simulator** page and select the assigned partner.
4. Drag the rider marker across the map.
5. Verify that the Customer Flutter App's live tracking map updates the rider pin location synchronously.
