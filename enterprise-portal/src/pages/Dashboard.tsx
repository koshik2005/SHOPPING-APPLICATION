// @ts-nocheck
import React from 'react';
import { Box, Grid, Card, CardContent, Typography } from '@mui/material';
import {
  Store as StoreIcon, Room as RoomIcon, ShoppingCart as ShoppingCartIcon,
  AttachMoney as MoneyIcon, SignalCellularAlt as StatusIcon
} from '@mui/icons-material';

export function Dashboard() {
  const stats = [
    { label: 'Active Branches', value: '1', icon: <RoomIcon sx={{ color: '#bb86fc', fontSize: 40 }} /> },
    { label: 'Merchant Shops', value: '1', icon: <StoreIcon sx={{ color: '#03dac6', fontSize: 40 }} /> },
    { label: 'Pending Orders', value: '0', icon: <ShoppingCartIcon sx={{ color: '#ffb74d', fontSize: 40 }} /> },
    { label: 'Total Earnings', value: '$50.00', icon: <MoneyIcon sx={{ color: '#81c784', fontSize: 40 }} /> },
  ];

  return (
    <Box>
      <Typography variant="h4" fontWeight="bold" gutterBottom mb={4}>
        Enterprise Control Center
      </Typography>

      <Grid container spacing={3} mb={4}>
        {stats.map((stat, i) => (
          <Grid item xs={12} sm={6} md={3} key={i}>
            <Card>
              <CardContent sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', p: 3 }}>
                <Box>
                  <Typography variant="body2" color="text.secondary" gutterBottom>
                    {stat.label}
                  </Typography>
                  <Typography variant="h4" fontWeight="bold">
                    {stat.value}
                  </Typography>
                </Box>
                {stat.icon}
              </CardContent>
            </Card>
          </Grid>
        ))}
      </Grid>

      <Grid container spacing={3}>
        <Grid item xs={12} md={8}>
          <Card sx={{ minHeight: 300 }}>
            <CardContent>
              <Typography variant="h6" fontWeight="bold" gutterBottom>
                Operational Health
              </Typography>
              <Box display="flex" flexDirection="column" gap={2} mt={3}>
                <Box display="flex" justifyContent="space-between" borderBottom="1px solid #2c2c2c" pb={1.5}>
                  <Typography variant="body2">API Gateway Routing</Typography>
                  <Typography variant="body2" color="success.main" fontWeight="bold">ONLINE</Typography>
                </Box>
                <Box display="flex" justifyContent="space-between" borderBottom="1px solid #2c2c2c" pb={1.5}>
                  <Typography variant="body2">Auth Service</Typography>
                  <Typography variant="body2" color="success.main" fontWeight="bold">ONLINE</Typography>
                </Box>
                <Box display="flex" justifyContent="space-between" borderBottom="1px solid #2c2c2c" pb={1.5}>
                  <Typography variant="body2">Inventory Service</Typography>
                  <Typography variant="body2" color="success.main" fontWeight="bold">ONLINE</Typography>
                </Box>
                <Box display="flex" justifyContent="space-between">
                  <Typography variant="body2">Order Service</Typography>
                  <Typography variant="body2" color="success.main" fontWeight="bold">ONLINE</Typography>
                </Box>
              </Box>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} md={4}>
          <Card sx={{ minHeight: 300 }}>
            <CardContent>
              <Typography variant="h6" fontWeight="bold" gutterBottom>
                Active Session Registry
              </Typography>
              <Typography variant="body2" color="text.secondary" mt={2}>
                All sessions are protected with refresh token rotation and active device fingerprint checks.
              </Typography>
              <Box display="flex" flexDirection="column" gap={1.5} mt={3}>
                <Typography variant="body2" fontWeight="bold">Security Statistics:</Typography>
                <Typography variant="caption" display="block">Active Device Bindings: 1</Typography>
                <Typography variant="caption" display="block">Risk Assessment: LOW</Typography>
                <Typography variant="caption" display="block">Audit Logs Written: 100%</Typography>
              </Box>
            </CardContent>
          </Card>
        </Grid>
      </Grid>
    </Box>
  );
}
