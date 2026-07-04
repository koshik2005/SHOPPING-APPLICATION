// @ts-nocheck
import React from 'react';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { ThemeProvider, CssBaseline } from '@mui/material';
import theme from './theme';
import { AuthProvider } from './auth/AuthContext';
import { ProtectedRoute } from './auth/ProtectedRoute';
import { LoginPage } from './auth/LoginPage';
import { Layout } from './components/Layout';

// Admin / Simulator pages
import { Dashboard } from './pages/Dashboard';
import UserManagement from './pages/UserManagement';
import RbacManagement from './pages/RbacManagement';
import BranchManagement from './pages/BranchManagement';
import DeliveryManagement from './pages/DeliveryManagement';
import WalletFinance from './pages/WalletFinance';
import SupportCenter from './pages/SupportCenter';
import SystemConfig from './pages/SystemConfig';
import SystemMonitor from './pages/SystemMonitor';
import SecurityCenter from './pages/SecurityCenter';

// Legacy Simulator Pages for fallback / simulation actions
import Shops from './pages/testing-simulator/Shops';
import Products from './pages/testing-simulator/Products';
import Inventory from './pages/testing-simulator/Inventory';
import Orders from './pages/testing-simulator/Orders';
import Payments from './pages/testing-simulator/Payments';
import Notifications from './pages/testing-simulator/Notifications';
import TestingTools from './pages/TestingTools';

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      refetchOnWindowFocus: false,
      retry: 1,
    },
  },
});

export default function App() {
  React.useEffect(() => {
    try {
      const channel = new BroadcastChannel('hyperlocal_session_channel');
      channel.postMessage({ type: 'PING_SESSION' });
      channel.onmessage = (event) => {
        if (event.data?.type === 'PING_SESSION') {
          channel.postMessage({ type: 'ACK_SESSION' });
        } else if (event.data?.type === 'ACK_SESSION') {
          alert("This account is already active in another browser tab. Please close the other tab to continue.");
          window.location.href = "about:blank";
        }
      };
      return () => channel.close();
    } catch (e) {
      // BroadcastChannel ignore fallback
    }
  }, []);

  return (
    <QueryClientProvider client={queryClient}>
      <ThemeProvider theme={theme}>
        <CssBaseline />
        <BrowserRouter>
          <AuthProvider>
            <Routes>
              {/* Public login route */}
              <Route path="/login" element={<LoginPage />} />

              {/* Protected admin shell routes */}
              <Route
                path="/"
                element={
                  <ProtectedRoute>
                    <Layout />
                  </ProtectedRoute>
                }
              >
                {/* Index / Dashboard */}
                <Route index element={<Dashboard />} />

                {/* Scoped admin modules */}
                <Route
                  path="branches"
                  element={
                    <ProtectedRoute requirePermission="branches:view">
                      <BranchManagement />
                    </ProtectedRoute>
                  }
                />
                <Route
                  path="shops"
                  element={
                    <ProtectedRoute requirePermission="shops:view">
                      <Shops />
                    </ProtectedRoute>
                  }
                />
                <Route
                  path="products"
                  element={
                    <ProtectedRoute requirePermission="products:view">
                      <Products />
                    </ProtectedRoute>
                  }
                />
                <Route
                  path="inventory"
                  element={
                    <ProtectedRoute requirePermission="inventory:view">
                      <Inventory />
                    </ProtectedRoute>
                  }
                />
                <Route
                  path="orders"
                  element={
                    <ProtectedRoute requirePermission="orders:view">
                      <Orders />
                    </ProtectedRoute>
                  }
                />
                <Route
                  path="delivery"
                  element={
                    <ProtectedRoute requirePermission="delivery:view">
                      <DeliveryManagement />
                    </ProtectedRoute>
                  }
                />
                <Route
                  path="payments"
                  element={
                    <ProtectedRoute requirePermission="payments:view">
                      <Payments />
                    </ProtectedRoute>
                  }
                />
                <Route
                  path="wallet"
                  element={
                    <ProtectedRoute requirePermission="wallet:view">
                      <WalletFinance />
                    </ProtectedRoute>
                  }
                />
                <Route
                  path="customers"
                  element={
                    <ProtectedRoute requirePermission="customers:view">
                      <UserManagement />
                    </ProtectedRoute>
                  }
                />
                <Route
                  path="notifications"
                  element={
                    <ProtectedRoute requirePermission="notifications:view">
                      <Notifications />
                    </ProtectedRoute>
                  }
                />
                <Route
                  path="users"
                  element={
                    <ProtectedRoute requirePermission="users:view">
                      <UserManagement />
                    </ProtectedRoute>
                  }
                />
                <Route
                  path="rbac"
                  element={
                    <ProtectedRoute requirePermission="users:view">
                      <RbacManagement />
                    </ProtectedRoute>
                  }
                />
                <Route
                  path="security-center"
                  element={
                    <ProtectedRoute requirePermission="users:view">
                      <SecurityCenter />
                    </ProtectedRoute>
                  }
                />
                <Route
                  path="audit-logs"
                  element={
                    <ProtectedRoute requirePermission="audit-logs:view">
                      <SystemMonitor />
                    </ProtectedRoute>
                  }
                />
                <Route
                  path="system-settings"
                  element={
                    <ProtectedRoute requirePermission="system-settings:view">
                      <SystemConfig />
                    </ProtectedRoute>
                  }
                />
                <Route
                  path="support"
                  element={
                    <ProtectedRoute requirePermission="customers:view">
                      <SupportCenter />
                    </ProtectedRoute>
                  }
                />

                {/* Developer / QA Testing Tools tab */}
                <Route
                  path="testing-tools"
                  element={
                    <ProtectedRoute requirePermission="testing-tools:view">
                      <TestingTools />
                    </ProtectedRoute>
                  }
                />

                {/* Catch all */}
                <Route path="*" element={<Navigate to="/" replace />} />
              </Route>
            </Routes>
          </AuthProvider>
        </BrowserRouter>
      </ThemeProvider>
    </QueryClientProvider>
  );
}
