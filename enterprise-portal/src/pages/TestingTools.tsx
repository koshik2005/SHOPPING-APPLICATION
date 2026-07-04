// @ts-nocheck
import React, { useState } from 'react';
import { Box, Typography, Card, Grid, List, ListItem, ListItemButton, ListItemIcon, ListItemText, Divider } from '@mui/material';
import {
  Dashboard as DashIcon, Room as RoomIcon, Store as StoreIcon,
  Inventory as BoxIcon, ListAlt as OrderIcon, LocalShipping as DeliverIcon,
  AccountBalanceWallet as WalletIcon, Payment as PayIcon, People as PeopleIcon,
  Notifications as BellIcon, Image as BannerIcon, LocalOffer as OfferIcon,
  Search as SearchIcon, Map as MapIcon, Settings as ConfigIcon,
  VpnKey as KeyIcon, Announcement as MonitorIcon, Storage as DbIcon
} from '@mui/icons-material';

// Import all simulator sub-pages dynamically/statically
import SimulatorDashboard from './testing-simulator/Dashboard';
import SimulatorBranches from './testing-simulator/Branches';
import SimulatorShops from './testing-simulator/Shops';
import SimulatorProducts from './testing-simulator/Products';
import SimulatorInventory from './testing-simulator/Inventory';
import SimulatorOrders from './testing-simulator/Orders';
import SimulatorDelivery from './testing-simulator/Delivery';
import SimulatorWallet from './testing-simulator/Wallet';
import SimulatorPayments from './testing-simulator/Payments';
import SimulatorUsers from './testing-simulator/Users';
import SimulatorNotifications from './testing-simulator/Notifications';
import SimulatorBanners from './testing-simulator/Banners';
import SimulatorOffers from './testing-simulator/Offers';
import SimulatorSearch from './testing-simulator/Search';
import SimulatorLocation from './testing-simulator/Location';
import SimulatorPermissions from './testing-simulator/Permissions';
import SimulatorMonitor from './testing-simulator/Monitor';
import SimulatorDatabase from './testing-simulator/Database';
import SimulatorConfig from './testing-simulator/Config';

const SIMULATOR_MODULES = [
  { text: 'Simulator Dashboard', icon: <DashIcon />, component: <SimulatorDashboard /> },
  { text: 'Live Event Monitor (SSE)', icon: <MonitorIcon />, component: <SimulatorMonitor /> },
  { text: 'Branch Operations', icon: <RoomIcon />, component: <SimulatorBranches /> },
  { text: 'Merchant Shops', icon: <StoreIcon />, component: <SimulatorShops /> },
  { text: 'Product Catalog', icon: <BoxIcon />, component: <SimulatorProducts /> },
  { text: 'Inventory Stock', icon: <BoxIcon />, component: <SimulatorInventory /> },
  { text: 'Order State Machine', icon: <OrderIcon />, component: <SimulatorOrders /> },
  { text: 'Delivery Partner GPS', icon: <DeliverIcon />, component: <SimulatorDelivery /> },
  { text: 'Wallet Credit/Debit', icon: <WalletIcon />, component: <SimulatorWallet /> },
  { text: 'Payment Gateway Injection', icon: <PayIcon />, component: <SimulatorPayments /> },
  { text: 'User Profiles', icon: <PeopleIcon />, component: <SimulatorUsers /> },
  { text: 'Push Notifications', icon: <BellIcon />, component: <SimulatorNotifications /> },
  { text: 'Marketing Banners', icon: <BannerIcon />, component: <SimulatorBanners /> },
  { text: 'Coupons & Offers', icon: <OfferIcon />, component: <SimulatorOffers /> },
  { text: 'Search Indices', icon: <SearchIcon />, component: <SimulatorSearch /> },
  { text: 'Interactive Map Movers', icon: <MapIcon />, component: <SimulatorLocation /> },
  { text: 'App Permissions Flags', icon: <KeyIcon />, component: <SimulatorPermissions /> },
  { text: 'Database Snapshot', icon: <DbIcon />, component: <SimulatorDatabase /> },
  { text: 'Global App Settings', icon: <ConfigIcon />, component: <SimulatorConfig /> },
];

export default function TestingTools() {
  const [activeTab, setActiveTab] = useState(0);

  return (
    <Box>
      <Typography variant="h4" fontWeight="bold" gutterBottom mb={3}>
        QA & Developer Simulation Tools
      </Typography>
      <Typography variant="body2" color="text.secondary" mb={4}>
        Simulate real-time business and gateway operations to verify the Customer and Delivery Partner apps behave dynamically.
      </Typography>

      <Grid container spacing={3}>
        <Grid item xs={12} md={3}>
          <Card sx={{ p: 1, maxHeight: 'calc(100vh - 220px)', overflowY: 'auto' }}>
            <List>
              {SIMULATOR_MODULES.map((mod, i) => {
                const active = activeTab === i;
                return (
                  <ListItem key={mod.text} disablePadding>
                    <ListItemButton
                      onClick={() => setActiveTab(i)}
                      selected={active}
                      sx={{
                        borderRadius: 1.5,
                        my: 0.25,
                        '&.Mui-selected': {
                          backgroundColor: 'rgba(3, 218, 198, 0.12)',
                          color: '#03dac6',
                          '& .MuiListItemIcon-root': {
                            color: '#03dac6',
                          },
                        },
                      }}
                    >
                      <ListItemIcon sx={{ minWidth: 36, color: 'text.secondary' }}>
                        {mod.icon}
                      </ListItemIcon>
                      <ListItemText primary={mod.text} primaryTypographyProps={{ fontSize: 13, fontWeight: active ? 600 : 500 }} />
                    </ListItemButton>
                  </ListItem>
                );
              })}
            </List>
          </Card>
        </Grid>

        <Grid item xs={12} md={9}>
          <Card sx={{ p: 3, minHeight: 600 }}>
            {SIMULATOR_MODULES[activeTab].component}
          </Card>
        </Grid>
      </Grid>
    </Box>
  );
}
