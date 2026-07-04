// @ts-nocheck
import React, { useState, useEffect } from 'react';
import {
  Box, Typography, Card, CardContent, Grid, Chip, Switch, FormControlLabel,
  Button, Dialog, DialogTitle, DialogContent, DialogActions, TextField,
  IconButton, Table, TableHead, TableBody, TableRow, TableCell, CircularProgress, Alert
} from '@mui/material';
import { Add as AddIcon, Edit as EditIcon, Refresh as RefreshIcon } from '@mui/icons-material';
import client from '../api/client';

interface PlatformService {
  id: string;
  serviceKey: string;
  displayName: string;
  iconUrl: string;
  colorHex: string;
  routePath: string;
  active: boolean;
  displayOrder: number;
  featureFlagKey: string;
}

export default function ServiceRegistry() {
  const [services, setServices] = useState<PlatformService[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [dialogOpen, setDialogOpen] = useState(false);
  const [editingService, setEditingService] = useState<Partial<PlatformService>>({});
  const [saving, setSaving] = useState(false);

  const load = async () => {
    setLoading(true);
    try {
      const res = await client.get('/api/v1/config/services');
      setServices(res.data?.data?.services || []);
      setError(null);
    } catch (e: any) {
      setError('Failed to load services: ' + (e.message || 'Unknown error'));
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { load(); }, []);

  const handleToggle = async (serviceKey: string, current: boolean) => {
    try {
      await client.patch(`/api/v1/config/services/${serviceKey}/toggle?active=${!current}`);
      setServices(prev => prev.map(s => s.serviceKey === serviceKey ? { ...s, active: !current } : s));
    } catch (e) {
      console.error('Toggle failed:', e);
    }
  };

  const handleSave = async () => {
    setSaving(true);
    try {
      if (editingService.id) {
        await client.put(`/api/v1/config/services/${editingService.serviceKey}`, editingService);
      } else {
        await client.post('/api/v1/config/services', editingService);
      }
      setDialogOpen(false);
      setEditingService({});
      await load();
    } catch (e) {
      console.error('Save failed:', e);
    } finally {
      setSaving(false);
    }
  };

  return (
    <Box>
      <Box display="flex" justifyContent="space-between" alignItems="center" mb={3}>
        <Box>
          <Typography variant="h4" fontWeight="bold" color="primary">
            Service Registry
          </Typography>
          <Typography color="text.secondary" mt={0.5}>
            Manage which services are available on the platform. Changes take effect immediately — no code deployment needed.
          </Typography>
        </Box>
        <Box display="flex" gap={1}>
          <IconButton onClick={load} disabled={loading}><RefreshIcon /></IconButton>
          <Button
            variant="contained"
            startIcon={<AddIcon />}
            onClick={() => { setEditingService({}); setDialogOpen(true); }}
            sx={{ background: 'linear-gradient(135deg, #bb86fc, #7c4dff)' }}
          >
            Add Service
          </Button>
        </Box>
      </Box>

      {error && <Alert severity="error" sx={{ mb: 2 }}>{error}</Alert>}

      {loading ? (
        <Box display="flex" justifyContent="center" mt={6}><CircularProgress /></Box>
      ) : (
        <Grid container spacing={2}>
          {services.map(service => (
            <Grid item xs={12} sm={6} md={4} key={service.serviceKey}>
              <Card sx={{
                background: 'linear-gradient(145deg, #1a1a2e, #16213e)',
                borderRadius: 3,
                border: `1px solid ${service.active ? service.colorHex + '44' : '#333'}`,
                transition: 'all 0.3s ease',
                '&:hover': { transform: 'translateY(-2px)', boxShadow: `0 8px 24px ${service.colorHex}22` }
              }}>
                <CardContent>
                  <Box display="flex" justifyContent="space-between" alignItems="flex-start" mb={1}>
                    <Box display="flex" alignItems="center" gap={1.5}>
                      <Typography fontSize="2rem">{service.iconUrl?.length <= 2 ? service.iconUrl : '🛍️'}</Typography>
                      <Box>
                        <Typography fontWeight="bold" color="text.primary">{service.displayName}</Typography>
                        <Typography variant="caption" color="text.secondary">{service.serviceKey}</Typography>
                      </Box>
                    </Box>
                    <Chip
                      label={service.active ? 'Active' : 'Inactive'}
                      size="small"
                      color={service.active ? 'success' : 'default'}
                    />
                  </Box>
                  <Typography variant="caption" color="text.secondary" display="block" mb={1}>
                    Route: {service.routePath}
                  </Typography>
                  <Box display="flex" justifyContent="space-between" alignItems="center">
                    <FormControlLabel
                      control={
                        <Switch
                          checked={service.active}
                          onChange={() => handleToggle(service.serviceKey, service.active)}
                          size="small"
                        />
                      }
                      label={<Typography variant="caption">{service.active ? 'Enabled' : 'Disabled'}</Typography>}
                    />
                    <IconButton
                      size="small"
                      onClick={() => { setEditingService(service); setDialogOpen(true); }}
                    >
                      <EditIcon fontSize="small" />
                    </IconButton>
                  </Box>
                </CardContent>
              </Card>
            </Grid>
          ))}
        </Grid>
      )}

      <Dialog open={dialogOpen} onClose={() => setDialogOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle>{editingService.id ? 'Edit Service' : 'Add New Service'}</DialogTitle>
        <DialogContent>
          <Box display="flex" flexDirection="column" gap={2} mt={1}>
            <TextField label="Service Key" value={editingService.serviceKey || ''} disabled={!!editingService.id}
              onChange={e => setEditingService(p => ({ ...p, serviceKey: e.target.value }))} />
            <TextField label="Display Name" value={editingService.displayName || ''}
              onChange={e => setEditingService(p => ({ ...p, displayName: e.target.value }))} />
            <TextField label="Icon (Material icon name or emoji)" value={editingService.iconUrl || ''}
              onChange={e => setEditingService(p => ({ ...p, iconUrl: e.target.value }))} />
            <TextField label="Color Hex (e.g. #FF6D00)" value={editingService.colorHex || ''}
              onChange={e => setEditingService(p => ({ ...p, colorHex: e.target.value }))} />
            <TextField label="App Route Path (e.g. /shop/food)" value={editingService.routePath || ''}
              onChange={e => setEditingService(p => ({ ...p, routePath: e.target.value }))} />
            <TextField label="Display Order" type="number" value={editingService.displayOrder ?? 0}
              onChange={e => setEditingService(p => ({ ...p, displayOrder: parseInt(e.target.value) }))} />
          </Box>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setDialogOpen(false)}>Cancel</Button>
          <Button variant="contained" onClick={handleSave} disabled={saving}>
            {saving ? <CircularProgress size={20} /> : 'Save'}
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
}
