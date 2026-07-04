// @ts-nocheck
import React, { useState, useEffect } from 'react';
import {
  Box, Card, CardContent, Typography, Grid, Button, Switch,
  FormControlLabel, TextField, Alert, MenuItem, Divider, CircularProgress
} from '@mui/material';
import { Save, Refresh } from '@mui/icons-material';
import client from '../api/client';

export default function SystemConfig() {
  const [config, setConfig] = useState<Record<String, String>>({});
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);

  const load = async () => {
    setLoading(true);
    try {
      const res = await client.get('/api/v1/config/system?category=PLATFORM_SETTINGS');
      // Direct merge of response data config
      const data = res.data?.data?.config || {};
      setConfig(data);
      setError(null);
    } catch (e: any) {
      setError('Failed to load system configurations');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { load(); }, []);

  const handleUpdate = async (key: string, value: string) => {
    setConfig(prev => ({ ...prev, [key]: value }));
  };

  const handleSave = async () => {
    setSaving(true);
    setSuccess(null);
    setError(null);
    try {
      // Loop over and save each config value
      for (const [key, val] of Object.entries(config)) {
        await client.post('/api/v1/config/system', {
          key,
          value: val,
          category: 'PLATFORM_SETTINGS'
        });
      }
      setSuccess('All system configuration values saved successfully!');
    } catch (e: any) {
      setError('Failed to save configuration: ' + (e.message || 'Unknown error'));
    } finally {
      setSaving(false);
    }
  };

  if (loading) {
    return (
      <Box display="flex" justifyContent="center" mt={8}>
        <CircularProgress />
      </Box>
    );
  }

  return (
    <Box>
      <Typography variant="h4" fontWeight="bold" gutterBottom mb={4}>
        System Configuration & Keys
      </Typography>

      {success && <Alert severity="success" sx={{ mb: 3 }}>{success}</Alert>}
      {error && <Alert severity="error" sx={{ mb: 3 }}>{error}</Alert>}

      <Grid container spacing={3}>
        <Grid item xs={12} md={6}>
          <Card sx={{ mb: 3, background: 'linear-gradient(145deg, #1a1a2e, #16213e)', borderRadius: 3, border: '1px solid #2c2c2c' }}>
            <CardContent sx={{ display: 'flex', flexDirection: 'column', gap: 2.5 }}>
              <Typography variant="h6" fontWeight="bold" color="primary">
                Operational Flags
              </Typography>
              
              <FormControlLabel
                control={
                  <Switch
                    checked={config['platform.maintenance_mode'] === 'true'}
                    onChange={(e) => handleUpdate('platform.maintenance_mode', e.target.checked ? 'true' : 'false')}
                    color="error"
                  />
                }
                label={<Typography color="white">System Maintenance Mode (Bypasses Non-Admins)</Typography>}
              />
              <FormControlLabel
                control={
                  <Switch
                    checked={config['feature.mfa'] === 'true'}
                    onChange={(e) => handleUpdate('feature.mfa', e.target.checked ? 'true' : 'false')}
                    color="primary"
                  />
                }
                label={<Typography color="white">Enforce Multi-Factor Authentication (MFA)</Typography>}
              />
              
              <Divider sx={{ borderColor: '#333' }} />

              <TextField
                select
                fullWidth
                label="Default Platform Currency"
                value={config['platform.currency.default'] || 'INR'}
                onChange={(e) => handleUpdate('platform.currency.default', e.target.value)}
                InputLabelProps={{ style: { color: '#aaa' } }}
                SelectProps={{ style: { color: 'white' } }}
              >
                <MenuItem value="USD">USD ($) - United States Dollar</MenuItem>
                <MenuItem value="EUR">EUR (€) - Euro</MenuItem>
                <MenuItem value="INR">INR (₹) - Indian Rupee</MenuItem>
                <MenuItem value="GBP">GBP (£) - British Pound</MenuItem>
              </TextField>

              <TextField
                fullWidth
                label="Base Platform Tax Rate (%)"
                type="number"
                value={config['platform.tax.gst_rate'] || '18.0'}
                onChange={(e) => handleUpdate('platform.tax.gst_rate', e.target.value)}
                InputLabelProps={{ style: { color: '#aaa' } }}
                inputProps={{ style: { color: 'white' } }}
              />

              <Button
                variant="contained"
                color="primary"
                startIcon={<Save />}
                onClick={handleSave}
                disabled={saving}
                sx={{ background: 'linear-gradient(135deg, #bb86fc, #7c4dff)' }}
              >
                {saving ? <CircularProgress size={24} /> : 'Save System Parameters'}
              </Button>
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} md={6}>
          <Card sx={{ mb: 3, background: 'linear-gradient(145deg, #1a1a2e, #16213e)', borderRadius: 3, border: '1px solid #2c2c2c' }}>
            <CardContent sx={{ display: 'flex', flexDirection: 'column', gap: 2.5 }}>
              <Typography variant="h6" fontWeight="bold" color="primary">
                SMTP Configuration
              </Typography>
              <TextField
                fullWidth
                label="SMTP Server Host"
                value={config['smtp.host'] || 'mailhog'}
                onChange={(e) => handleUpdate('smtp.host', e.target.value)}
                InputLabelProps={{ style: { color: '#aaa' } }}
                inputProps={{ style: { color: 'white' } }}
              />
              <TextField
                fullWidth
                label="SMTP Port"
                value={config['smtp.port'] || '1025'}
                onChange={(e) => handleUpdate('smtp.port', e.target.value)}
                InputLabelProps={{ style: { color: '#aaa' } }}
                inputProps={{ style: { color: 'white' } }}
              />
              <TextField
                fullWidth
                label="SMTP Sender Address"
                value={config['smtp.from'] || 'noreply@hyperlocal.app'}
                onChange={(e) => handleUpdate('smtp.from', e.target.value)}
                InputLabelProps={{ style: { color: '#aaa' } }}
                inputProps={{ style: { color: 'white' } }}
              />
              <Button
                variant="contained"
                color="primary"
                startIcon={<Save />}
                onClick={handleSave}
                disabled={saving}
                sx={{ background: 'linear-gradient(135deg, #bb86fc, #7c4dff)' }}
              >
                Save SMTP Parameters
              </Button>
            </CardContent>
          </Card>
        </Grid>
      </Grid>
    </Box>
  );
}
