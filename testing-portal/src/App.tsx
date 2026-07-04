// @ts-nocheck
import React from 'react';
import { Routes, Route, Navigate } from 'react-router-dom';
import { ThemeProvider, CssBaseline } from '@mui/material';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import theme from './theme';
import Layout from './components/Layout';
import Dashboard from './pages/Dashboard';
import Branches from './pages/Branches';
import Shops from './pages/Shops';
import Categories from './pages/Categories';
import Products from './pages/Products';
import Inventory from './pages/Inventory';
import Orders from './pages/Orders';
import Delivery from './pages/Delivery';
import Wallet from './pages/Wallet';
import Payments from './pages/Payments';
import Users from './pages/Users';
import Notifications from './pages/Notifications';
import Banners from './pages/Banners';
import Offers from './pages/Offers';
import Search from './pages/Search';
import Location from './pages/Location';
import Permissions from './pages/Permissions';
import Monitor from './pages/Monitor';
import Database from './pages/Database';
import Config from './pages/Config';

import { AuthProvider } from './auth/AuthContext';
import { ProtectedRoute } from './auth/ProtectedRoute';
import { LoginPage } from './auth/LoginPage';

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      retry: 1,
      staleTime: 2000,
    },
  },
});

export default function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <ThemeProvider theme={theme}>
        <CssBaseline />
        <AuthProvider>
          <Routes>
            {/* Public route */}
            <Route path="/login" element={<LoginPage />} />

            {/* Protected dashboard views inside dynamic Layout */}
            <Route
              path="/"
              element={
                <ProtectedRoute>
                  <Layout />
                </ProtectedRoute>
              }
            >
              <Route index element={<Dashboard />} />
              <Route path="branches" element={<Branches />} />
              <Route path="shops" element={<Shops />} />
              <Route path="categories" element={<Categories />} />
              <Route path="products" element={<Products />} />
              <Route path="inventory" element={<Inventory />} />
              <Route path="orders" element={<Orders />} />
              <Route path="delivery" element={<Delivery />} />
              <Route path="wallet" element={<Wallet />} />
              <Route path="payments" element={<Payments />} />
              <Route path="users" element={<Users />} />
              <Route path="notifications" element={<Notifications />} />
              <Route path="banners" element={<Banners />} />
              <Route path="offers" element={<Offers />} />
              <Route path="search" element={<Search />} />
              <Route path="location" element={<Location />} />
              <Route path="permissions" element={<Permissions />} />
              <Route path="monitor" element={<Monitor />} />
              <Route path="database" element={<Database />} />
              <Route path="config" element={<Config />} />
            </Route>

            {/* Catch-all redirect */}
            <Route path="*" element={<Navigate to="/" />} />
          </Routes>
        </AuthProvider>
      </ThemeProvider>
    </QueryClientProvider>
  );
}
