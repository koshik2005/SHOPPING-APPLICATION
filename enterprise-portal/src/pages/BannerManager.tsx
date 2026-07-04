// @ts-nocheck
import React, { useState, useEffect } from 'react';
import {
  Box, Typography, Card, CardContent, Button, Dialog, DialogTitle,
  DialogContent, DialogActions, TextField, IconButton, CircularProgress,
  Alert, Grid, Chip, Select, MenuItem, FormControl, InputLabel, Stack
} from '@mui/material';
import { Add as AddIcon, Delete as DeleteIcon, Refresh as RefreshIcon } from '@mui/icons-material';
import client from '../api/client';

interface Banner {
  id: string;
  title: string;
  subtitle: string;
  actionRoute: string;
  backgroundColors: string[];
  iconKey: string;
  imageUrl: string;
  displayOrder: number;
  active: boolean;
  validFrom: string;
  validTo: string;
}

export default function BannerManager() {
  const [banners, setBanners] = useState<Banner[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [dialogOpen, setDialogOpen] = useState(false);
  const [editing, setEditing] = useState<Partial<Banner>>({});
  const [saving, setSaving] = useState(false);
  const [colorsInput, setColorsInput] = useState('');

  const load = async () => {
    setLoading(true);
    try {
      const res = await client.get('/api/v1/config/banners');
      setBanners(res.data?.data?.banners || []);
      setError(null);
    } catch (e: any) { setError('Failed to load banners'); }
    finally { setLoading(false); }
  };

  useEffect(() => { load(); }, []);

  const openCreate = () => {
    setEditing({ active: true, displayOrder: banners.length + 1 });
    setColorsInput('');
    setDialogOpen(true);
  };

  const openEdit = (b: Banner) => {
    setEditing(b);
    setColorsInput((b.backgroundColors || []).join(', '));
    setDialogOpen(true);
  };

  const handleSave = async () => {
    setSaving(true);
    try {
      const payload = {
        ...editing,
        backgroundColors: colorsInput.split(',').map(c => c.trim()).filter(Boolean),
      };
      if (editing.id) {
        await client.put(`/api/v1/config/banners/${editing.id}`, payload);
      } else {
        await client.post('/api/v1/config/banners', payload);
      }
      setDialogOpen(false);
      await load();
    } catch (e) { console.error('Save failed:', e); }
    finally { setSaving(false); }
  };

  const handleDelete = async (id: string) => {
    if (!window.confirm('Delete this banner?')) return;
    try {
      await client.delete(`/api/v1/config/banners/${id}`);
      await load();
    } catch (e) { console.error('Delete failed:', e); }
  };

  return (
    <Box>
      <Box display="flex" justifyContent="space-between" alignItems="center" mb={3}>
        <Box>
          <Typography variant="h4" fontWeight="bold" color="primary">Banner Manager</Typography>
          <Typography color="text.secondary" mt={0.5}>
            Manage promotional banners shown on the Flutter home screen.
          </Typography>
        </Box>
        <Box display="flex" gap={1}>
          <IconButton onClick={load} disabled={loading}><RefreshIcon /></IconButton>
          <Button variant="contained" startIcon={<AddIcon />} onClick={openCreate}
            sx={{ background: 'linear-gradient(135deg, #bb86fc, #7c4dff)' }}>
            Add Banner
          </Button>
        </Box>
      </Box>

      {error && <Alert severity="error" sx={{ mb: 2 }}>{error}</Alert>}

      {loading ? <Box display="flex" justifyContent="center" mt={6}><CircularProgress /></Box> : (
        <Grid container spacing={3}>
          {banners.map(banner => {
            const colors = banner.backgroundColors || ['#1565C0', '#0D47A1'];
            return (
              <Grid item xs={12} sm={6} md={4} key={banner.id}>
                <Card sx={{
                  borderRadius: 4, overflow: 'hidden', position: 'relative',
                  background: `linear-gradient(135deg, ${colors.join(', ')})`,
                  minHeight: 160,
                  cursor: 'pointer',
                  '&:hover': { transform: 'scale(1.02)', transition: 'transform 0.2s' }
                }} onClick={() => openEdit(banner)}>
                  <CardContent>
                    <Box display="flex" justifyContent="space-between">
                      <Box>
                        <Typography variant="h6" fontWeight="bold" color="white">{banner.title}</Typography>
                        <Typography variant="body2" color="rgba(255,255,255,0.8)">{banner.subtitle}</Typography>
                        <Typography variant="caption" color="rgba(255,255,255,0.6)">Route: {banner.actionRoute}</Typography>
                        <Stack direction="row" spacing={1} mt={1}>
                          <Chip label={banner.active ? 'Active' : 'Inactive'} size="small"
                            color={banner.active ? 'success' : 'default'} />
                          <Chip label={`#${banner.displayOrder}`} size="small" />
                        </Stack>
                      </Box>
                      <Box>
                        <IconButton size="small" sx={{ color: 'white' }}
                          onClick={e => { e.stopPropagation(); handleDelete(banner.id); }}>
                          <DeleteIcon fontSize="small" />
                        </IconButton>
                      </Box>
                    </Box>
                  </CardContent>
                </Card>
              </Grid>
            );
          })}
          {banners.length === 0 && (
            <Grid item xs={12}>
              <Alert severity="info">No banners configured. Click "Add Banner" to create the first one.</Alert>
            </Grid>
          )}
        </Grid>
      )}

      <Dialog open={dialogOpen} onClose={() => setDialogOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle>{editing.id ? 'Edit Banner' : 'Create Banner'}</DialogTitle>
        <DialogContent>
          <Box display="flex" flexDirection="column" gap={2} mt={1}>
            <TextField label="Title" value={editing.title || ''}
              onChange={e => setEditing(p => ({ ...p, title: e.target.value }))} />
            <TextField label="Subtitle" value={editing.subtitle || ''}
              onChange={e => setEditing(p => ({ ...p, subtitle: e.target.value }))} />
            <TextField label="Action Route (deep-link on tap)" value={editing.actionRoute || ''}
              onChange={e => setEditing(p => ({ ...p, actionRoute: e.target.value }))} />
            <TextField
              label="Background Colors (comma-separated hex)"
              value={colorsInput}
              onChange={e => setColorsInput(e.target.value)}
              helperText="Example: #1565C0, #0D47A1"
            />
            <TextField label="Icon Key (Material icon name or emoji)" value={editing.iconKey || ''}
              onChange={e => setEditing(p => ({ ...p, iconKey: e.target.value }))} />
            <TextField label="Display Order" type="number" value={editing.displayOrder ?? 1}
              onChange={e => setEditing(p => ({ ...p, displayOrder: parseInt(e.target.value) }))} />
            <FormControl fullWidth>
              <InputLabel>Status</InputLabel>
              <Select value={editing.active ? 'active' : 'inactive'} label="Status"
                onChange={e => setEditing(p => ({ ...p, active: e.target.value === 'active' }))}>
                <MenuItem value="active">Active</MenuItem>
                <MenuItem value="inactive">Inactive</MenuItem>
              </Select>
            </FormControl>
            <TextField label="Valid From (ISO timestamp, optional)" value={editing.validFrom || ''}
              onChange={e => setEditing(p => ({ ...p, validFrom: e.target.value || null }))} />
            <TextField label="Valid To (ISO timestamp, optional)" value={editing.validTo || ''}
              onChange={e => setEditing(p => ({ ...p, validTo: e.target.value || null }))} />
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
