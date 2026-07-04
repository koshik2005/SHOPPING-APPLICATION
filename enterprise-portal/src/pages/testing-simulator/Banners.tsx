// @ts-nocheck
import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import {
  Box, Typography, Button, Grid, Card, CardContent, CardActions, CardMedia,
  Chip, Dialog, DialogTitle, DialogContent, DialogActions, TextField,
  Snackbar, Stack, Switch, FormControlLabel, IconButton, Alert,
} from '@mui/material';
import { Add, Delete, ToggleOff, ToggleOn, Image } from '@mui/icons-material';
import { getBanners, createBanner, toggleBanner, deleteBanner } from '../../api/portal';

const EMPTY = { title: '', imageUrl: '', linkUrl: '', priority: 1 };
const PLACEHOLDER_COLORS = ['#6366f1', '#06b6d4', '#10b981', '#f59e0b', '#ef4444', '#8b5cf6', '#ec4899'];

export default function Banners() {
  const qc = useQueryClient();
  const { data: banners = [] } = useQuery({ queryKey: ['banners'], queryFn: getBanners });
  const [open, setOpen] = useState(false);
  const [form, setForm] = useState<any>(EMPTY);
  const [snack, setSnack] = useState('');

  const createM = useMutation({ mutationFn: createBanner, onSuccess: () => { qc.invalidateQueries({ queryKey: ['banners'] }); setOpen(false); setSnack('Banner created!'); } });
  const toggleM = useMutation({ mutationFn: toggleBanner, onSuccess: () => { qc.invalidateQueries({ queryKey: ['banners'] }); setSnack('Banner toggled!'); } });
  const deleteM = useMutation({ mutationFn: deleteBanner, onSuccess: () => { qc.invalidateQueries({ queryKey: ['banners'] }); setSnack('Banner deleted!'); } });

  const set = (k: string, v: any) => setForm((f: any) => ({ ...f, [k]: v }));
  const placeholderColor = (i: number) => PLACEHOLDER_COLORS[i % PLACEHOLDER_COLORS.length];

  return (
    <Box>
      <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 3 }}>
        <Box>
          <Typography variant="h5" fontWeight={700}>Banner Simulator</Typography>
          <Typography color="text.secondary" fontSize="0.85rem">Create and manage homepage promotional banners. Toggle active/inactive without deleting.</Typography>
        </Box>
        <Button variant="contained" startIcon={<Add />} onClick={() => { setForm(EMPTY); setOpen(true); }}>New Banner</Button>
      </Box>

      {banners.length === 0 && (
        <Alert severity="info" sx={{ mb: 2 }}>No banners. Create one to simulate the customer app's promotional carousel.</Alert>
      )}

      <Grid container spacing={2}>
        {[...banners].sort((a: any, b: any) => a.priority - b.priority).map((b: any, i: number) => (
          <Grid item xs={12} sm={6} md={4} key={b.id}>
            <Card sx={{ opacity: b.isActive ? 1 : 0.5 }}>
              {b.imageUrl ? (
                <CardMedia component="img" height="120" image={b.imageUrl} alt={b.title} sx={{ objectFit: 'cover' }} />
              ) : (
                <Box sx={{ height: 120, bgcolor: placeholderColor(i), display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                  <Image sx={{ color: 'white', opacity: 0.5, fontSize: 48 }} />
                </Box>
              )}
              <CardContent sx={{ pb: 0 }}>
                <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <Typography fontWeight={700} fontSize="0.9rem">{b.title || '(no title)'}</Typography>
                  <Box sx={{ display: 'flex', gap: 0.5 }}>
                    <Chip label={b.isActive ? 'ACTIVE' : 'INACTIVE'} size="small" color={b.isActive ? 'success' : 'default'} />
                    <Chip label={`P${b.priority}`} size="small" />
                  </Box>
                </Box>
                {b.linkUrl && <Typography fontSize="0.72rem" color="text.secondary" sx={{ mt: 0.5, wordBreak: 'break-all' }}>{b.linkUrl}</Typography>}
              </CardContent>
              <CardActions sx={{ px: 2, pb: 2 }}>
                <Button size="small" startIcon={b.isActive ? <ToggleOff /> : <ToggleOn />} onClick={() => toggleM.mutate(b.id)} variant="outlined" color={b.isActive ? 'warning' : 'success'}>
                  {b.isActive ? 'Deactivate' : 'Activate'}
                </Button>
                <Button size="small" startIcon={<Delete />} onClick={() => deleteM.mutate(b.id)} color="error" variant="outlined">Delete</Button>
              </CardActions>
            </Card>
          </Grid>
        ))}
      </Grid>

      <Dialog open={open} onClose={() => setOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle>Create New Banner</DialogTitle>
        <DialogContent>
          <Stack spacing={2} sx={{ mt: 1 }}>
            <TextField label="Banner Title" value={form.title ?? ''} onChange={e => set('title', e.target.value)} fullWidth required />
            <TextField label="Image URL" value={form.imageUrl ?? ''} onChange={e => set('imageUrl', e.target.value)} fullWidth helperText="Leave empty for a color placeholder" />
            <TextField label="Link URL" value={form.linkUrl ?? ''} onChange={e => set('linkUrl', e.target.value)} fullWidth />
            <TextField label="Priority (1=highest)" type="number" value={form.priority ?? 1} onChange={e => set('priority', parseInt(e.target.value))} fullWidth inputProps={{ min: 1 }} />
          </Stack>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setOpen(false)}>Cancel</Button>
          <Button variant="contained" onClick={() => createM.mutate(form)} disabled={createM.isPending}>Create</Button>
        </DialogActions>
      </Dialog>

      <Snackbar open={!!snack} autoHideDuration={3000} onClose={() => setSnack('')} message={snack} anchorOrigin={{ vertical: 'bottom', horizontal: 'right' }} />
    </Box>
  );
}
