// @ts-nocheck
import React, { useState } from 'react';
import {
  Box, Card, CardContent, Typography, Grid, Button, Switch,
  FormControlLabel, TextField, Alert, MenuItem, Divider
} from '@mui/material';
import { Save, Refresh, SettingsInputComponent } from '@mui/icons-material';

export default function SystemConfig() {
  const [maintenance, setMaintenance] = useState(false);
  const [mfa, setMfa] = useState(false);
  const [currency, setCurrency] = useState('USD');
  const [tax, setTax] = useState('0.08');
  const [apiKey, setApiKey] = useState('key-f83b2072a716c9011ff83');

  const handleRotateKey = () => {
    setApiKey('key-' + Math.random().toString(36).substr(2, 20));
  };

  return (
    <Box>
      <Typography variant="h4" fontWeight="bold" gutterBottom mb={4}>
        System Configuration & Keys
      </Typography>

      <Grid container spacing={3}>
        <Grid item xs={12} md={6}>
          <Card sx={{ mb: 3 }}>
            <CardContent sx={{ display: 'flex', flexDirection: 'column', gap: 2.5 }}>
              <Typography variant="h6" fontWeight="bold">
                Operational Flags
              </Typography>
              <FormControlLabel
                control={
                  <Switch
                    checked={maintenance}
                    onChange={(e) => setMaintenance(e.target.checked)}
                    color="error"
                  />
                }
                label="System Maintenance Mode (Bypasses Non-Admins)"
              />
              <FormControlLabel
                control={
                  <Switch
                    checked={mfa}
                    onChange={(e) => setMfa(e.target.checked)}
                    color="primary"
                  />
                }
                label="Enforce Multi-Factor Authentication (MFA)"
              />
              <Divider />
              <TextField
                select
                fullWidth
                label="Default Platform Currency"
                value={currency}
                onChange={(e) => setCurrency(e.target.value)}
              >
                <MenuItem value="USD">USD ($) - United States Dollar</MenuItem>
                <MenuItem value="EUR">EUR (€) - Euro</MenuItem>
                <MenuItem value="INR">INR (₹) - Indian Rupee</MenuItem>
              </TextField>

              <TextField
                fullWidth
                label="Base Platform Tax Rate"
                type="number"
                value={tax}
                onChange={(e) => setTax(e.target.value)}
              />
              <Button variant="contained" color="primary" startIcon={<Save />}>
                Save System Parameters
              </Button>
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} md={6}>
          <Card sx={{ mb: 3 }}>
            <CardContent sx={{ display: 'flex', flexDirection: 'column', gap: 2.5 }}>
              <Typography variant="h6" fontWeight="bold">
                Active API Secrets
              </Typography>
              <Typography variant="body2" color="text.secondary">
                This secret signs outgoing integration events. Rotate this key quarterly to ensure cryptographic integrity.
              </Typography>
              <TextField
                fullWidth
                disabled
                label="Internal Event Signing Key"
                value={apiKey}
              />
              <Button
                variant="outlined"
                color="secondary"
                startIcon={<Refresh />}
                onClick={handleRotateKey}
              >
                Rotate Cryptographic Key
              </Button>
            </CardContent>
          </Card>

          <Card>
            <CardContent sx={{ display: 'flex', flexDirection: 'column', gap: 2.5 }}>
              <Typography variant="h6" fontWeight="bold">
                SMTP Configuration
              </Typography>
              <TextField fullWidth label="SMTP Server Host" value="mailhog" disabled />
              <TextField fullWidth label="SMTP Port" value="1025" disabled />
              <TextField fullWidth label="SMTP Sender Address" value="noreply@hyperlocal.app" disabled />
            </CardContent>
          </Card>
        </Grid>
      </Grid>
    </Box>
  );
}
