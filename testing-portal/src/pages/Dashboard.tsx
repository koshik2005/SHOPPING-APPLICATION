// @ts-nocheck
import React from 'react';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import { Grid, Box, Typography, Card, CardContent, Divider, LinearProgress, Chip } from '@mui/material';
import {
  ShoppingCart, AccountTree, Storefront, Category, Inventory, DeliveryDining,
  AccountBalanceWallet, TrendingUp, WifiTethering, NotificationsActive,
} from '@mui/icons-material';
import StatCard from '../components/StatCard';
import EventLog from '../components/EventLog';
import { getDashboard } from '../api/portal';

export default function Dashboard() {
  const { data, isLoading } = useQuery({ queryKey: ['dashboard'], queryFn: getDashboard, refetchInterval: 5000 });

  const stats = [
    { label: 'Total Orders',       value: data?.totalOrders,       icon: <ShoppingCart />,          color: '#6366f1', sub: `${data?.pendingOrders ?? 0} pending` },
    { label: 'Branches',           value: data?.totalBranches,      icon: <AccountTree />,           color: '#06b6d4' },
    { label: 'Active Shops',       value: data?.activeShops,        icon: <Storefront />,            color: '#10b981' },
    { label: 'Categories',         value: data?.totalCategories,    icon: <Category />,              color: '#f59e0b' },
    { label: 'Products',           value: data?.totalProducts,      icon: <Inventory />,             color: '#8b5cf6' },
    { label: 'Delivery Partners',  value: data?.deliveryPartners,   icon: <DeliveryDining />,        color: '#06b6d4', sub: `${data?.onlinePartners ?? 0} online` },
    { label: 'Wallet Balance',     value: data?.walletBalance,      icon: <AccountBalanceWallet />,  color: '#10b981', prefix: '$' },
    { label: 'Revenue (Simulated)',value: data?.todayRevenue,       icon: <TrendingUp />,            color: '#6366f1', prefix: '$' },
    { label: 'Customers',          value: data?.totalCustomers,     icon: <AccountTree />,           color: '#f59e0b' },
    { label: 'SSE Connections',    value: data?.sseSubscribers,     icon: <WifiTethering />,         color: '#10b981', sub: `${data?.eventLogCount ?? 0} events logged` },
    { label: 'Pending Onboarding', value: data?.pendingOnboarding,  icon: <NotificationsActive />,   color: '#ef4444' },
    { label: 'Pending Orders',     value: data?.pendingOrders,      icon: <ShoppingCart />,          color: '#f59e0b' },
  ];

  return (
    <Box>
      {/* Header */}
      <Box sx={{ mb: 3 }}>
        <Typography variant="h4" sx={{ fontWeight: 800, mb: 0.5 }}>
          Simulation Dashboard
        </Typography>
        <Typography color="text.secondary" sx={{ fontSize: '0.9rem' }}>
          Real-time overview of the HyperLocal mock backend. Auto-refreshes every 5 seconds.
        </Typography>
        <Chip
          label="Live Data · database.json"
          size="small"
          sx={{ mt: 1, bgcolor: 'rgba(16,185,129,0.1)', color: '#34d399', border: '1px solid rgba(16,185,129,0.25)', fontSize: '0.7rem' }}
        />
      </Box>

      {/* Stats grid */}
      <Grid container spacing={2} sx={{ mb: 3 }}>
        {stats.map(s => (
          <Grid item xs={12} sm={6} md={4} lg={3} key={s.label}>
            <StatCard {...s} loading={isLoading} />
          </Grid>
        ))}
      </Grid>

      <Divider sx={{ my: 3, borderColor: '#1f2937' }} />

      {/* Live Event Monitor */}
      <Box>
        <Typography variant="h6" sx={{ fontWeight: 700, mb: 1 }}>
          Live Event Stream
        </Typography>
        <Typography color="text.secondary" sx={{ fontSize: '0.82rem', mb: 2 }}>
          All simulation actions broadcast here in real-time via Server-Sent Events.
        </Typography>
        <EventLog maxHeight={320} />
      </Box>
    </Box>
  );
}
