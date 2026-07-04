// @ts-nocheck
import React, { useState } from 'react';
import { useNavigate, useLocation, Outlet } from 'react-router-dom';
import { useAuth } from '../auth/useAuth';
import {
  Box, Drawer, AppBar, Toolbar, List, Typography, Divider, IconButton,
  ListItem, ListItemButton, ListItemIcon, ListItemText, Avatar, Menu, MenuItem
} from '@mui/material';
import {
  Menu as MenuIcon, Dashboard as DashboardIcon, Room as RoomIcon,
  Store as StoreIcon, Inventory as InventoryIcon, ShoppingCart as ShoppingCartIcon,
  People as PeopleIcon, LocalShipping as LocalShippingIcon, AccountBalanceWallet as WalletIcon,
  ReceiptLong as ReceiptIcon, Notifications as NotificationsIcon, AdminPanelSettings as AdminIcon,
  Security as SecurityIcon, Settings as SettingsIcon, BugReport as BugIcon,
  Assessment as AssessmentIcon, Help as HelpIcon, ExitToApp as LogoutIcon
} from '@mui/icons-material';

const drawerWidth = 260;

export function Layout() {
  const { user, logout } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();
  const [anchorEl, setAnchorEl] = useState<null | HTMLElement>(null);

  const handleMenu = (event: React.MouseEvent<HTMLElement>) => {
    setAnchorEl(event.currentTarget);
  };

  const handleClose = () => {
    setAnchorEl(null);
  };

  const handleLogoutClick = async () => {
    handleClose();
    await logout();
  };

  const SIDEBAR_ITEMS = [
    { text: 'Dashboard', icon: <DashboardIcon />, path: '/', permission: 'dashboard:view' },
    { text: 'Branches', icon: <RoomIcon />, path: '/branches', permission: 'branches:view' },
    { text: 'Shops', icon: <StoreIcon />, path: '/shops', permission: 'shops:view' },
    { text: 'Products', icon: <InventoryIcon />, path: '/products', permission: 'products:view' },
    { text: 'Inventory', icon: <AssessmentIcon />, path: '/inventory', permission: 'inventory:view' },
    { text: 'Orders', icon: <ShoppingCartIcon />, path: '/orders', permission: 'orders:view' },
    { text: 'Delivery tracking', icon: <LocalShippingIcon />, path: '/delivery', permission: 'delivery:view' },
    { text: 'Payments', icon: <ReceiptIcon />, path: '/payments', permission: 'payments:view' },
    { text: 'Wallet ledger', icon: <WalletIcon />, path: '/wallet', permission: 'wallet:view' },
    { text: 'Customers', icon: <PeopleIcon />, path: '/customers', permission: 'customers:view' },
    { text: 'Notifications', icon: <NotificationsIcon />, path: '/notifications', permission: 'notifications:view' },
    { text: 'User management', icon: <AdminIcon />, path: '/users', permission: 'users:view' },
    { text: 'RBAC Settings', icon: <SecurityIcon />, path: '/rbac', permission: 'users:view' },
    { text: 'Security Center', icon: <AdminIcon />, path: '/security-center', permission: 'users:view' },
    { text: 'Resolution Center', icon: <HelpIcon />, path: '/support', permission: 'customers:view' },
    { text: 'Audit logs', icon: <SecurityIcon />, path: '/audit-logs', permission: 'audit-logs:view' },
    { text: 'System settings', icon: <SettingsIcon />, path: '/system-settings', permission: 'system-settings:view' },
    { text: 'Testing Tools', icon: <BugIcon />, path: '/testing-tools', permission: 'testing-tools:view' }
  ];

  const { can } = useAuth();

  // Filter sidebar items according to user permissions
  const filteredItems = SIDEBAR_ITEMS.filter(item => can(item.permission));

  return (
    <Box sx={{ display: 'flex' }}>
      <AppBar
        position="fixed"
        sx={{
          zIndex: (theme) => theme.zIndex.drawer + 1,
          backgroundColor: '#121212',
          borderBottom: '1px solid #2c2c2c',
        }}
      >
        <Toolbar>
          <Typography variant="h6" noWrap component="div" sx={{ flexGrow: 1, fontWeight: 'bold', color: '#bb86fc' }}>
            HyperLocal Admin Portal
          </Typography>
          {user && (
            <Box display="flex" alignItems="center" gap={1.5}>
              <Typography variant="body2" color="text.secondary">
                {user.email} ({user.role.replace('ROLE_', '')})
              </Typography>
              <IconButton onClick={handleMenu} sx={{ p: 0 }}>
                <Avatar sx={{ bgcolor: '#bb86fc', color: '#000' }}>
                  {user.email.charAt(0).toUpperCase()}
                </Avatar>
              </IconButton>
              <Menu
                id="menu-appbar"
                anchorEl={anchorEl}
                anchorOrigin={{ vertical: 'top', horizontal: 'right' }}
                keepMounted
                transformOrigin={{ vertical: 'top', horizontal: 'right' }}
                open={Boolean(anchorEl)}
                onClose={handleClose}
              >
                <MenuItem onClick={handleClose}>Profile Settings</MenuItem>
                <MenuItem onClick={handleLogoutClick}>
                  <ListItemIcon>
                    <LogoutIcon fontSize="small" />
                  </ListItemIcon>
                  Sign Out
                </MenuItem>
              </Menu>
            </Box>
          )}
        </Toolbar>
      </AppBar>

      <Drawer
        variant="permanent"
        sx={{
          width: drawerWidth,
          flexShrink: 0,
          [`& .MuiDrawer-paper`]: {
            width: drawerWidth,
            boxSizing: 'border-box',
            backgroundColor: '#1e1e1e',
            borderRight: '1px solid #2c2c2c',
          },
        }}
      >
        <Toolbar />
        <Box sx={{ overflow: 'auto', mt: 2 }}>
          <List>
            {filteredItems.map((item) => {
              const active = location.pathname === item.path;
              return (
                <ListItem key={item.text} disablePadding>
                  <ListItemButton
                    onClick={() => navigate(item.path)}
                    selected={active}
                    sx={{
                      mx: 1,
                      my: 0.5,
                      borderRadius: 1.5,
                      '&.Mui-selected': {
                        backgroundColor: 'rgba(187, 134, 252, 0.12)',
                        color: '#bb86fc',
                        '& .MuiListItemIcon-root': {
                          color: '#bb86fc',
                        },
                      },
                    }}
                  >
                    <ListItemIcon sx={{ minWidth: 40, color: 'text.secondary' }}>
                      {item.icon}
                    </ListItemIcon>
                    <ListItemText primary={item.text} primaryTypographyProps={{ fontSize: 14, fontWeight: active ? 600 : 500 }} />
                  </ListItemButton>
                </ListItem>
              );
            })}
          </List>
        </Box>
      </Drawer>

      <Box component="main" sx={{ flexGrow: 1, p: 4, minHeight: '100vh', backgroundColor: '#121212' }}>
        <Toolbar />
        <Outlet />
      </Box>
    </Box>
  );
}
