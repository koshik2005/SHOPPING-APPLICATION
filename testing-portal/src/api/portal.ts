// @ts-nocheck
import api from './client';

// ─── Dashboard ────────────────────────────────────────────────────────────────
export const getDashboard = () => api.get('/api/portal/dashboard').then(r => r.data.data);
export const getDbSnapshot = () => api.get('/api/portal/db-snapshot').then(r => r.data.data);

// ─── Branches ─────────────────────────────────────────────────────────────────
export const getBranches = () => api.get('/api/portal/branches').then(r => r.data.data);
export const createBranch = (d: any) => api.post('/api/portal/branches/create', d);
export const updateBranch = (d: any) => api.post('/api/portal/branches/update', d);
export const deleteBranch = (id: string) => api.post('/api/portal/branches/delete', { id });

// ─── Shops ────────────────────────────────────────────────────────────────────
export const getShops = () => api.get('/api/portal/shops').then(r => r.data.data);
export const createShop = (d: any) => api.post('/api/portal/shops/create', d);
export const toggleShop = (id: string) => api.post('/api/portal/shops/toggle', { id });
export const updateShop = (d: any) => api.post('/api/portal/shops/update', d);
export const deleteShop = (id: string) => api.post('/api/portal/shops/delete', { id });

// ─── Categories ───────────────────────────────────────────────────────────────
export const getCategories = () => api.get('/api/portal/categories').then(r => r.data.data);
export const createCategory = (d: any) => api.post('/api/portal/categories/create', d);
export const updateCategory = (d: any) => api.post('/api/portal/categories/update', d);
export const deleteCategory = (id: string) => api.post('/api/portal/categories/delete', { id });

// ─── Products ─────────────────────────────────────────────────────────────────
export const getProducts = () => api.get('/api/portal/products').then(r => r.data.data);
export const createProduct = (d: any) => api.post('/api/portal/products/create', d);
export const toggleProduct = (id: string) => api.post('/api/portal/products/toggle', { id });
export const updateProduct = (d: any) => api.post('/api/portal/products/update', d);
export const deleteProduct = (id: string) => api.post('/api/portal/products/delete', { id });

// ─── Inventory ────────────────────────────────────────────────────────────────
export const adjustInventory = (productId: string, delta?: number, setTo?: number) =>
  api.post('/api/portal/inventory/adjust', { productId, delta, setTo });

// ─── Orders ───────────────────────────────────────────────────────────────────
export const getOrders = () => api.get('/api/portal/orders').then(r => r.data.data);
export const createTestOrder = (d: any) => api.post('/api/portal/orders/create-test', d);
export const advanceOrderStatus = (orderId: string, status: string, remarks?: string) =>
  api.post('/api/portal/orders/advance-status', { orderId, status, remarks });

// ─── Wallet ───────────────────────────────────────────────────────────────────
export const adjustWallet = (amount: number, operation: 'CREDIT' | 'DEBIT') =>
  api.post('/api/portal/wallet/adjust', { amount, operation });

// ─── Payments ─────────────────────────────────────────────────────────────────
export const injectPayment = (orderId: string, result: string) =>
  api.post('/api/portal/payment/inject', { orderId, result });

// ─── Notifications ────────────────────────────────────────────────────────────
export const getNotifications = () => api.get('/api/portal/notifications').then(r => r.data.data);
export const sendNotification = (d: any) => api.post('/api/portal/notifications/send', d);

// ─── Banners ──────────────────────────────────────────────────────────────────
export const getBanners = () => api.get('/api/portal/banners').then(r => r.data.data);
export const createBanner = (d: any) => api.post('/api/portal/banners/create', d);
export const toggleBanner = (id: string) => api.post('/api/portal/banners/toggle', { id });
export const deleteBanner = (id: string) => api.post('/api/portal/banners/delete', { id });

// ─── Offers ───────────────────────────────────────────────────────────────────
export const getOffers = () => api.get('/api/portal/offers').then(r => r.data.data);
export const createOffer = (d: any) => api.post('/api/portal/offers/create', d);
export const toggleOffer = (id: string) => api.post('/api/portal/offers/toggle', { id });
export const deleteOffer = (id: string) => api.post('/api/portal/offers/delete', { id });

// ─── Config ───────────────────────────────────────────────────────────────────
export const getConfig = () => api.get('/api/portal/config').then(r => r.data.data);
export const updateConfig = (d: any) => api.post('/api/portal/config/update', d);

// ─── Users ────────────────────────────────────────────────────────────────────
export const getUsers = () => api.get('/api/portal/users').then(r => r.data.data);
export const createUser = (d: any) => api.post('/api/portal/users/create', d);
export const manageUser = (email: string, action: 'SUSPEND' | 'ACTIVATE' | 'DELETE') =>
  api.post('/api/portal/users/manage', { email, action });

// ─── Delivery Partners ────────────────────────────────────────────────────────
export const getPartners = () => api.get('/api/portal/partners').then(r => r.data.data);
export const moveRider = (partnerId: string, latitude: number, longitude: number) =>
  api.post('/api/portal/delivery/move-rider', { partnerId, latitude, longitude });

// ─── Permissions ──────────────────────────────────────────────────────────────
export const setPermissions = (d: any) => api.post('/api/portal/permissions/set', d);
