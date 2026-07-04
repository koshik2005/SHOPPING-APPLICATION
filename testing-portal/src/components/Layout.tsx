// @ts-nocheck
import React, { useState } from 'react';
import { useLocation, useNavigate, Link } from 'react-router-dom';
import {
  Box, Drawer, List, ListItem, ListItemIcon, ListItemText, ListItemButton,
  AppBar, Toolbar, Typography, IconButton, Chip, Divider, Avatar, Tooltip,
  Badge,
} from '@mui/material';
import {
  Dashboard, AccountTree, Store, Category, Inventory, ShoppingCart,
  DeliveryDining, AccountBalanceWallet, Payment, Person, Notifications,
  ViewCarousel, LocalOffer, Search, Map, Security, Stream, Storage, Settings,
  RadioButtonChecked, GitHub, BugReport, Storefront, ExitToApp as LogoutIcon,
} from '@mui/icons-material';
import { useAuth } from '../auth/useAuth';

const DRAWER_WIDTH = 248;

interface NavItem {
  label: string;
  icon: React.ReactNode;
  path: string;
  badge?: string;
  color?: string;
  group?: string;
}

const NAV: NavItem[] = [
  { label: 'Dashboard',        icon: <Dashboard />,          path: '/',              group: 'Overview' },
  { label: 'Config',           icon: <Settings />,           path: '/config',        group: 'Overview' },
  { label: 'Database',         icon: <Storage />,            path: '/database',      group: 'Overview' },
  { label: 'Live Monitor',     icon: <Stream />,             path: '/monitor',       group: 'Overview',  badge: 'LIVE', color: '#10b981' },
  { label: 'Branches',         icon: <AccountTree />,        path: '/branches',      group: 'Commerce' },
  { label: 'Shops',            icon: <Storefront />,         path: '/shops',         group: 'Commerce' },
  { label: 'Categories',       icon: <Category />,           path: '/categories',    group: 'Commerce' },
  { label: 'Products',         icon: <Inventory />,          path: '/products',      group: 'Commerce' },
  { label: 'Inventory',        icon: <Store />,              path: '/inventory',     group: 'Commerce' },
  { label: 'Orders',           icon: <ShoppingCart />,       path: '/orders',        group: 'Transactions' },
  { label: 'Delivery',         icon: <DeliveryDining />,     path: '/delivery',      group: 'Transactions' },
  { label: 'Wallet',           icon: <AccountBalanceWallet />, path: '/wallet',      group: 'Transactions' },
  { label: 'Payments',         icon: <Payment />,            path: '/payments',      group: 'Transactions' },
  { label: 'Users',            icon: <Person />,             path: '/users',         group: 'Platform' },
  { label: 'Notifications',    icon: <Notifications />,      path: '/notifications', group: 'Platform' },
  { label: 'Banners',          icon: <ViewCarousel />,       path: '/banners',       group: 'Platform' },
  { label: 'Offers',           icon: <LocalOffer />,         path: '/offers',        group: 'Platform' },
  { label: 'Search',           icon: <Search />,             path: '/search',        group: 'Platform' },
  { label: 'Location',         icon: <Map />,                path: '/location',      group: 'Simulation' },
  { label: 'Permissions',      icon: <Security />,           path: '/permissions',   group: 'Simulation' },
];

const GROUPS = ['Overview', 'Commerce', 'Transactions', 'Platform', 'Simulation'];

export default function Layout({ children }: { children: React.ReactNode }) {
  const location = useLocation();
  const navigate = useNavigate();
  const { user, logout } = useAuth();

  const currentPage = NAV.find(n => n.path === location.pathname)?.label ?? 'Dashboard';

  return (
    <Box sx={{ display: 'flex', minHeight: '100vh', bgcolor: 'background.default' }}>
      {/* Sidebar */}
      <Drawer
        variant="permanent"
        sx={{
          width: DRAWER_WIDTH,
          flexShrink: 0,
          '& .MuiDrawer-paper': {
            width: DRAWER_WIDTH,
            bgcolor: '#0d1220',
            borderRight: '1px solid #1f2937',
            overflow: 'hidden',
            display: 'flex',
            flexDirection: 'column',
          },
        }}
      >
        {/* Logo */}
        <Box sx={{ p: 2.5, borderBottom: '1px solid #1f2937' }}>
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5 }}>
            <Box
              sx={{
                width: 38, height: 38, borderRadius: 2,
                background: 'linear-gradient(135deg, #6366f1 0%, #06b6d4 100%)',
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                flexShrink: 0,
              }}
            >
              <BugReport sx={{ color: 'white', fontSize: 20 }} />
            </Box>
            <Box>
              <Typography variant="subtitle2" sx={{ color: '#f9fafb', fontWeight: 700, lineHeight: 1.2, fontSize: '0.85rem' }}>
                HyperLocal
              </Typography>
              <Typography sx={{ color: '#6366f1', fontSize: '0.68rem', fontWeight: 600, letterSpacing: '0.06em', textTransform: 'uppercase' }}>
                Testing Portal
              </Typography>
            </Box>
          </Box>
          <Chip
            label="DEV ONLY"
            size="small"
            sx={{
              mt: 1.5, height: 18, fontSize: '0.6rem', fontWeight: 700,
              bgcolor: 'rgba(239,68,68,0.15)', color: '#f87171',
              border: '1px solid rgba(239,68,68,0.3)',
            }}
          />
        </Box>

        {/* Nav */}
        <Box sx={{ flex: 1, overflowY: 'auto', py: 1 }}>
          {GROUPS.map(group => {
            const items = NAV.filter(n => n.group === group);
            return (
              <Box key={group} sx={{ mb: 0.5 }}>
                <Typography
                  sx={{
                    px: 2, py: 0.75, color: '#4b5563', fontSize: '0.65rem',
                    fontWeight: 700, textTransform: 'uppercase', letterSpacing: '0.08em',
                  }}
                >
                  {group}
                </Typography>
                {items.map(item => {
                  const active = location.pathname === item.path;
                  return (
                    <ListItemButton
                      key={item.path}
                      component={Link}
                      to={item.path}
                      sx={{
                        mx: 1, my: 0.2, borderRadius: 2, px: 1.5, py: 0.8,
                        bgcolor: active ? 'rgba(99,102,241,0.15)' : 'transparent',
                        '&:hover': { bgcolor: active ? 'rgba(99,102,241,0.2)' : 'rgba(255,255,255,0.04)' },
                        borderLeft: active ? '3px solid #6366f1' : '3px solid transparent',
                        transition: 'all 0.15s',
                      }}
                    >
                      <ListItemIcon
                        sx={{
                          minWidth: 34,
                          color: active ? '#6366f1' : '#6b7280',
                          '& .MuiSvgIcon-root': { fontSize: 18 },
                        }}
                      >
                        {item.icon}
                      </ListItemIcon>
                      <ListItemText
                        primary={item.label}
                        primaryTypographyProps={{
                          fontSize: '0.8rem',
                          fontWeight: active ? 600 : 400,
                          color: active ? '#f9fafb' : '#9ca3af',
                        }}
                      />
                      {item.badge && (
                        <Chip
                          label={item.badge}
                          size="small"
                          sx={{
                            height: 16, fontSize: '0.58rem', fontWeight: 700,
                            bgcolor: 'rgba(16,185,129,0.15)', color: '#34d399',
                            border: '1px solid rgba(16,185,129,0.3)',
                          }}
                        />
                      )}
                    </ListItemButton>
                  );
                })}
              </Box>
            );
          })}
        </Box>

        {/* Footer */}
        <Box sx={{ p: 2, borderTop: '1px solid #1f2937' }}>
          {user && (
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5, mb: 1.5, pb: 1.5, borderBottom: '1px solid #1f2937' }}>
              <Avatar sx={{ bgcolor: '#6366f1', width: 32, height: 32, fontSize: '0.9rem' }}>
                {user.email ? user.email[0].toUpperCase() : 'U'}
              </Avatar>
              <Box sx={{ flex: 1, minWidth: 0 }}>
                <Typography variant="caption" sx={{ color: '#f9fafb', fontWeight: 600, display: 'block', noWrap: true, overflow: 'hidden', textOverflow: 'ellipsis' }}>
                  {user.email}
                </Typography>
                <Typography variant="caption" sx={{ color: '#6b7280', display: 'block', textTransform: 'capitalize' }}>
                  {user.role ? user.role.replace('ROLE_', '').replace('_', ' ').toLowerCase() : 'user'}
                </Typography>
              </Box>
              <IconButton size="small" onClick={logout} sx={{ color: '#f87171' }}>
                <LogoutIcon sx={{ fontSize: 18 }} />
              </IconButton>
            </Box>
          )}
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
            <Box sx={{ width: 8, height: 8, borderRadius: '50%', bgcolor: '#10b981', animation: 'pulse 2s infinite', '@keyframes pulse': { '0%,100%': { opacity: 1 }, '50%': { opacity: 0.5 } } }} />
            <Typography sx={{ fontSize: '0.72rem', color: '#6b7280' }}>
              Backend :8080 active
            </Typography>
          </Box>
          <Typography sx={{ fontSize: '0.65rem', color: '#374151', mt: 0.5 }}>
            v1.0.0 · QA Engineers only
          </Typography>
        </Box>
      </Drawer>

      {/* Main content */}
      <Box sx={{ flex: 1, display: 'flex', flexDirection: 'column', minWidth: 0 }}>
        {/* Top bar */}
        <AppBar
          position="sticky"
          elevation={0}
          sx={{
            bgcolor: 'rgba(10,15,30,0.9)',
            backdropFilter: 'blur(12px)',
            borderBottom: '1px solid #1f2937',
          }}
        >
          <Toolbar sx={{ gap: 2, minHeight: '56px !important' }}>
            <Typography variant="h6" sx={{ fontSize: '1rem', fontWeight: 700, flex: 1 }}>
              {currentPage}
            </Typography>
            <Chip
              label="HyperLocal Simulator"
              size="small"
              sx={{ bgcolor: 'rgba(99,102,241,0.1)', color: '#818cf8', border: '1px solid rgba(99,102,241,0.3)', fontSize: '0.7rem' }}
            />
            <Tooltip title="Python Backend :8080">
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.8, cursor: 'pointer' }}>
                <Box sx={{ width: 8, height: 8, borderRadius: '50%', bgcolor: '#10b981' }} />
                <Typography sx={{ fontSize: '0.72rem', color: '#9ca3af' }}>API</Typography>
              </Box>
            </Tooltip>
          </Toolbar>
        </AppBar>

        {/* Page content */}
        <Box sx={{ flex: 1, p: 3, overflowY: 'auto' }}>
          {children}
        </Box>
      </Box>
    </Box>
  );
}
