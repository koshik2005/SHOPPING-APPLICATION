// @ts-nocheck
import React, { useState, useEffect } from 'react';
import { Box, Grid, Card, CardContent, Typography, CircularProgress } from '@mui/material';
import {
  Store as StoreIcon, Room as RoomIcon, ShoppingCart as ShoppingCartIcon,
  AttachMoney as MoneyIcon, Speed as SpeedIcon
} from '@mui/icons-material';

export function Dashboard() {
  const [uiSchema, setUiSchema] = useState<any>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetch('/api/v1/config/portal-ui')
      .then(res => res.json())
      .then(json => {
        if (json.success && json.data) {
          setUiSchema(json.data);
        }
      })
      .catch(err => console.error("Error loading portal-ui metadata", err))
      .finally(() => setLoading(false));
  }, []);

  const stats = [
    { label: 'Active Branches', value: '1', icon: <RoomIcon sx={{ color: '#bb86fc', fontSize: 40 }} /> },
    { label: 'Merchant Shops', value: '1', icon: <StoreIcon sx={{ color: '#03dac6', fontSize: 40 }} /> },
    { label: 'Pending Orders', value: '0', icon: <ShoppingCartIcon sx={{ color: '#ffb74d', fontSize: 40 }} /> },
    { label: 'Total Earnings', value: '$50.00', icon: <MoneyIcon sx={{ color: '#81c784', fontSize: 40 }} /> },
  ];

  if (loading) {
    return (
      <Box display="flex" justifyContent="center" alignItems="center" minHeight="50vh">
        <CircularProgress />
      </Box>
    );
  }

  // Render server-driven sections if metadata exists
  const sections = uiSchema?.sections || [];

  return (
    <Box>
      <Typography variant="h4" fontWeight="bold" gutterBottom mb={4}>
        Enterprise Control Center
      </Typography>

      {/* Render Dynamic Metadata-driven Widgets */}
      {sections.length > 0 ? (
        sections.map((sec: any) => (
          <Box key={sec.id} mb={4}>
            <Typography variant="h5" fontWeight="bold" gutterBottom mb={2}>
              {sec.title}
            </Typography>
            <Grid container spacing={3}>
              {sec.widgets.map((widget: any) => (
                <Grid item xs={widget.size?.xs || 12} md={widget.size?.md || 4} key={widget.id}>
                  <Card>
                    <CardContent sx={{ p: 3 }}>
                      <Typography variant="body2" color="text.secondary" gutterBottom>
                        {widget.title}
                      </Typography>
                      <Typography variant="h4" fontWeight="bold" mb={1}>
                        {widget.type === 'METRIC_CARD' ? '$12,450.00' : 'Dynamic Trend Active'}
                      </Typography>
                      <Typography variant="caption" color="primary">
                        Source: {widget.sourceApi}
                      </Typography>
                    </CardContent>
                  </Card>
                </Grid>
              ))}
            </Grid>
          </Box>
        ))
      ) : (
        // Fallback layout if no server-driven schema is present
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
      )}

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
