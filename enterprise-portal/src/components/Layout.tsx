// @ts-nocheck
import React, { useState } from 'react';
import { useNavigate, useLocation, Outlet } from 'react-router-dom';
import { useAuth } from '../auth/useAuth';
import { useNavigationMenu } from '../hooks/useNavigationMenu';
import {
  Box, Drawer, AppBar, Toolbar, List, Typography, Divider, IconButton,
  ListItem, ListItemButton, ListItemIcon, ListItemText, Avatar, Menu,
  MenuItem, CircularProgress, Tooltip
} from '@mui/material';
import {
  Menu as MenuIcon, ExitToApp as LogoutIcon,
  // Icon registry — maps iconKey strings from DB to MUI icon components
  Dashboard, Room, Store, Inventory, ShoppingCart, People, LocalShipping,
  AccountBalanceWallet, ReceiptLong, Notifications, AdminPanelSettings,
  Security, Settings, BugReport, Assessment, Help, ManageSearch,
  AppRegistration, ToggleOn, PriceChange, AccountTree, Image, Translate,
  Shield, DynamicForm
} from '@mui/icons-material';

const drawerWidth = 260;

/**
 * Icon Registry — maps iconKey strings from navigation_menus DB table
 * to MUI icon components. The content (which icons exist) is configured
 * in the DB; this file only provides the mapping adapter.
 *
 * NEW ICONS: Add the MUI import above and the mapping entry below.
 */
const ICON_REGISTRY: Record<string, React.ReactElement> = {
  Dashboard:             <Dashboard />,
  Room:                  <Room />,
  Store:                 <Store />,
  Inventory:             <Inventory />,
  ShoppingCart:          <ShoppingCart />,
  People:                <People />,
  LocalShipping:         <LocalShipping />,
  AccountBalanceWallet:  <AccountBalanceWallet />,
  ReceiptLong:           <ReceiptLong />,
  Notifications:         <Notifications />,
  AdminPanelSettings:    <AdminPanelSettings />,
  Security:              <Security />,
  Settings:              <Settings />,
  BugReport:             <BugReport />,
  Assessment:            <Assessment />,
  Help:                  <Help />,
  ManageSearch:          <ManageSearch />,
  AppRegistration:       <AppRegistration />,
  ToggleOn:              <ToggleOn />,
  PriceChange:           <PriceChange />,
  AccountTree:           <AccountTree />,
  Image:                 <Image />,
  Translate:             <Translate />,
  Shield:                <Shield />,
  DynamicForm:           <DynamicForm />,
};

function resolveIcon(iconKey: string): React.ReactElement {
  return ICON_REGISTRY[iconKey] || <Dashboard />;
}

export function Layout() {
  const { user, logout, can } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();
  const [anchorEl, setAnchorEl] = useState<null | HTMLElement>(null);

  // ─── Dynamic Navigation from backend API ──────────────────────────────────
  const { navItems, isLoaded: navLoaded } = useNavigationMenu('ENTERPRISE');

  // Filter items by permission AND group by section
  const permittedItems = navItems.filter(item =>
    !item.permissionKey || can(item.permissionKey)
  );

  // Group by sectionLabel for sidebar section dividers
  const sections: Record<string, NavMenuItem[]> = {};
  permittedItems.forEach(item => {
    const section = item.sectionLabel || 'OTHER';
    if (!sections[section]) sections[section] = [];
    sections[section].push(item);
  });

  const handleMenu = (event: React.MouseEvent<HTMLElement>) => {
    setAnchorEl(event.currentTarget);
  };
  const handleClose = () => setAnchorEl(null);
  const handleLogoutClick = async () => {
    handleClose();
    await logout();
  };

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
                  Logout
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
          '& .MuiDrawer-paper': {
            width: drawerWidth,
            boxSizing: 'border-box',
            backgroundColor: '#1a1a2e',
            borderRight: '1px solid #2c2c2c',
          },
        }}
      >
        <Toolbar />
        <Box sx={{ overflow: 'auto', mt: 1 }}>
          {!navLoaded ? (
            <Box display="flex" justifyContent="center" mt={4}>
              <CircularProgress size={24} sx={{ color: '#bb86fc' }} />
            </Box>
          ) : (
            <List dense>
              {Object.entries(sections).map(([sectionLabel, items], sIdx) => (
                <React.Fragment key={sectionLabel}>
                  {sIdx > 0 && <Divider sx={{ borderColor: '#2c2c2c', my: 0.5 }} />}
                  <Typography
                    variant="caption"
                    sx={{
                      px: 2,
                      py: 0.5,
                      display: 'block',
                      color: '#666',
                      textTransform: 'uppercase',
                      letterSpacing: '0.08em',
                      fontSize: '0.65rem',
                    }}
                  >
                    {sectionLabel}
                  </Typography>
                  {items.map((item) => {
                    const isActive =
                      item.routePath === '/'
                        ? location.pathname === '/'
                        : location.pathname.startsWith(item.routePath);
                    return (
                      <ListItem key={item.menuKey} disablePadding>
                        <Tooltip title={item.displayLabel} placement="right" arrow>
                          <ListItemButton
                            onClick={() => navigate(item.routePath)}
                            selected={isActive}
                            sx={{
                              mx: 1,
                              borderRadius: 1.5,
                              '&.Mui-selected': {
                                backgroundColor: '#bb86fc22',
                                color: '#bb86fc',
                                '& .MuiListItemIcon-root': { color: '#bb86fc' },
                              },
                              '&:hover': {
                                backgroundColor: '#bb86fc11',
                              },
                            }}
                          >
                            <ListItemIcon sx={{ minWidth: 36, color: isActive ? '#bb86fc' : '#888' }}>
                              {resolveIcon(item.iconKey)}
                            </ListItemIcon>
                            <ListItemText
                              primary={item.displayLabel}
                              primaryTypographyProps={{
                                fontSize: '0.82rem',
                                fontWeight: isActive ? 600 : 400,
                                color: isActive ? '#bb86fc' : '#ccc',
                              }}
                            />
                          </ListItemButton>
                        </Tooltip>
                      </ListItem>
                    );
                  })}
                </React.Fragment>
              ))}
            </List>
          )}
        </Box>
      </Drawer>

      <Box component="main" sx={{ flexGrow: 1, p: 3, mt: 8, backgroundColor: '#0a0a0a', minHeight: '100vh' }}>
        <Outlet />
      </Box>
    </Box>
  );
}
