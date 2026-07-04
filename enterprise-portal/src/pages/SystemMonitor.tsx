// @ts-nocheck
import React from 'react';
import { Box, Card, CardContent, Typography, Grid, LinearProgress, Alert } from '@mui/material';
import { NetworkCheck, Storage, CloudQueue, Terminal } from '@mui/icons-material';

export default function SystemMonitor() {
  return (
    <Box>
      <Typography variant="h4" fontWeight="bold" gutterBottom mb={4}>
        Platform Health & Telemetry
      </Typography>

      <Grid container spacing={3} mb={4}>
        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Typography variant="body2" color="text.secondary" gutterBottom>
                Gateway RAM Util
              </Typography>
              <Typography variant="h5" fontWeight="bold">
                42%
              </Typography>
              <LinearProgress variant="determinate" value={42} color="success" sx={{ mt: 2 }} />
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Typography variant="body2" color="text.secondary" gutterBottom>
                Auth Service CPU
              </Typography>
              <Typography variant="h5" fontWeight="bold">
                12%
              </Typography>
              <LinearProgress variant="determinate" value={12} color="success" sx={{ mt: 2 }} />
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Typography variant="body2" color="text.secondary" gutterBottom>
                Order Service CPU
              </Typography>
              <Typography variant="h5" fontWeight="bold">
                18%
              </Typography>
              <LinearProgress variant="determinate" value={18} color="success" sx={{ mt: 2 }} />
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Typography variant="body2" color="text.secondary" gutterBottom>
                Active DB Pool connections
              </Typography>
              <Typography variant="h5" fontWeight="bold">
                3 / 20
              </Typography>
              <LinearProgress variant="determinate" value={15} color="success" sx={{ mt: 2 }} />
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      <Grid container spacing={3}>
        <Grid item xs={12} md={6}>
          <Card sx={{ minHeight: 350 }}>
            <CardContent sx={{ display: 'flex', flexDirection: 'column', gap: 2.5 }}>
              <Typography variant="h6" fontWeight="bold">
                Downstream Services Telemetry
              </Typography>
              <Box display="flex" justifyContent="space-between" borderBottom="1px solid #2c2c2c" pb={1.5}>
                <Typography variant="body2" display="flex" alignItems="center" gap={1}>
                  <NetworkCheck color="success" /> API Gateway (:8080)
                </Typography>
                <Typography variant="body2" color="success.main" fontWeight="bold">ONLINE</Typography>
              </Box>
              <Box display="flex" justifyContent="space-between" borderBottom="1px solid #2c2c2c" pb={1.5}>
                <Typography variant="body2" display="flex" alignItems="center" gap={1}>
                  <Terminal color="success" /> Auth Service (:8081)
                </Typography>
                <Typography variant="body2" color="success.main" fontWeight="bold">ONLINE</Typography>
              </Box>
              <Box display="flex" justifyContent="space-between" borderBottom="1px solid #2c2c2c" pb={1.5}>
                <Typography variant="body2" display="flex" alignItems="center" gap={1}>
                  <Storage color="success" /> Inventory Service (:8083)
                </Typography>
                <Typography variant="body2" color="success.main" fontWeight="bold">ONLINE</Typography>
              </Box>
              <Box display="flex" justifyContent="space-between">
                <Typography variant="body2" display="flex" alignItems="center" gap={1}>
                  <CloudQueue color="success" /> Order Service (:8084)
                </Typography>
                <Typography variant="body2" color="success.main" fontWeight="bold">ONLINE</Typography>
              </Box>
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} md={6}>
          <Card sx={{ minHeight: 350 }}>
            <CardContent sx={{ display: 'flex', flexDirection: 'column', gap: 2.5 }}>
              <Typography variant="h6" fontWeight="bold">
                Logistics Message Broker (RabbitMQ)
              </Typography>
              <Box display="flex" justifyContent="space-between" borderBottom="1px solid #2c2c2c" pb={1.5}>
                <Typography variant="body2">Exchange: order.events</Typography>
                <Typography variant="body2" color="success.main" fontWeight="bold">ACTIVE</Typography>
              </Box>
              <Box display="flex" justifyContent="space-between" borderBottom="1px solid #2c2c2c" pb={1.5}>
                <Typography variant="body2">Queue: order.created</Typography>
                <Typography variant="body2">0 pending messages</Typography>
              </Box>
              <Box display="flex" justifyContent="space-between" borderBottom="1px solid #2c2c2c" pb={1.5}>
                <Typography variant="body2">Queue: payment.completed</Typography>
                <Typography variant="body2">0 pending messages</Typography>
              </Box>
              <Alert severity="success">
                All message queues are clean. Broker load is optimal.
              </Alert>
            </CardContent>
          </Card>
        </Grid>
      </Grid>
    </Box>
  );
}
