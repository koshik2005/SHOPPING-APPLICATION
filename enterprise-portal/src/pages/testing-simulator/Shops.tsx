// @ts-nocheck
import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import {
  Box, Typography, Button, Grid, Card, CardContent, CardActions, Chip,
  Dialog, DialogTitle, DialogContent, DialogActions, TextField, Switch,
  FormControlLabel, Alert, Snackbar, Stack, Rating,
} from '@mui/material';
import { Add, Edit, Delete, ToggleOn, ToggleOff } from '@mui/icons-material';
import { getShops, createShop, toggleShop, updateShop, deleteShop } from '../../api/portal';

const EMPTY = { name: '', isOpen: true, rating: 4.5, deliveryTime: '20-30 min', logoUrl: '', bannerUrl: '' };

export default function Shops() {
  const qc = useQueryClient();
  const { data: shops = [], isLoading } = useQuery({ queryKey: ['shops'], queryFn: getShops });
  const [open, setOpen] = useState(false);
  const [form, setForm] = useState<any>(EMPTY);
  const [editing, setEditing] = useState(false);
  const [snack, setSnack] = useState('');

  const createM = useMutation({ mutationFn: createShop, onSuccess: () => { qc.invalidateQueries({ queryKey: ['shops'] }); setOpen(false); setSnack('Shop created!'); } });
  const updateM = useMutation({ mutationFn: updateShop, onSuccess: () => { qc.invalidateQueries({ queryKey: ['shops'] }); setOpen(false); setSnack('Shop updated!'); } });
  const toggleM = useMutation({ mutationFn: toggleShop, onSuccess: () => { qc.invalidateQueries({ queryKey: ['shops'] }); setSnack('Shop toggled!'); } });
  const deleteM = useMutation({ mutationFn: deleteShop, onSuccess: () => { qc.invalidateQueries({ queryKey: ['shops'] }); setSnack('Shop deleted!'); } });

  const set = (k: string, v: any) => setForm((f: any) => ({ ...f, [k]: v }));
  const save = () => editing ? updateM.mutate(form) : createM.mutate(form);

  return (
    <Box>
      <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 3 }}>
        <Box>
          <Typography variant="h5" fontWeight={700}>Shop Simulator</Typography>
          <Typography color="text.secondary" fontSize="0.85rem">Create, toggle, and manage shops visible in the customer app.</Typography>
        </Box>
        <Button variant="contained" startIcon={<Add />} onClick={() => { setForm(EMPTY); setEditing(false); setOpen(true); }}>New Shop</Button>
      </Box>

      {shops.length === 0 && !isLoading && (
        <Alert severity="info">No shops configured. Create the first one!</Alert>
      )}

      <Grid container spacing={2}>
        {shops.map((s: any) => (
          <Grid item xs={12} sm={6} md={4} key={s.id}>
            <Card>
              <CardContent>
                <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 1 }}>
                  <Typography fontWeight={700} fontSize="0.95rem">{s.name}</Typography>
                  <Chip label={s.isOpen ? 'OPEN' : 'CLOSED'} size="small" color={s.isOpen ? 'success' : 'error'} />
                </Box>
                <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5, mb: 0.5 }}>
                  <Rating value={s.rating ?? 0} readOnly precision={0.5} size="small" />
                  <Typography fontSize="0.78rem" color="text.secondary">({s.rating})</Typography>
                </Box>
                <Typography fontSize="0.78rem" color="text.secondary">🚀 Delivery: {s.deliveryTime}</Typography>
                <Chip label={s.status ?? 'ACTIVE'} size="small" sx={{ mt: 0.5 }} color={s.status === 'ACTIVE' ? 'success' : 'default'} />
              </CardContent>
              <CardActions sx={{ px: 2, pb: 2, gap: 1 }}>
                <Button size="small" startIcon={<Edit />} onClick={() => { setForm({ ...s }); setEditing(true); setOpen(true); }} variant="outlined">Edit</Button>
                <Button size="small" startIcon={s.isOpen ? <ToggleOff /> : <ToggleOn />} onClick={() => toggleM.mutate(s.id)} variant="outlined" color={s.isOpen ? 'warning' : 'success'}>
                  {s.isOpen ? 'Close' : 'Open'}
                </Button>
                <Button size="small" startIcon={<Delete />} onClick={() => deleteM.mutate(s.id)} color="error" variant="outlined">Del</Button>
              </CardActions>
            </Card>
          </Grid>
        ))}
      </Grid>

      <Dialog open={open} onClose={() => setOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle>{editing ? 'Edit Shop' : 'Create New Shop'}</DialogTitle>
        <DialogContent>
          <Stack spacing={2} sx={{ mt: 1 }}>
            <TextField label="Shop Name" value={form.name ?? ''} onChange={e => set('name', e.target.value)} fullWidth required />
            <TextField label="Delivery Time (e.g. 20-30 min)" value={form.deliveryTime ?? ''} onChange={e => set('deliveryTime', e.target.value)} fullWidth />
            <TextField label="Rating (0-5)" type="number" inputProps={{ min: 0, max: 5, step: 0.1 }} value={form.rating ?? ''} onChange={e => set('rating', parseFloat(e.target.value))} fullWidth />
            <TextField label="Logo URL" value={form.logoUrl ?? ''} onChange={e => set('logoUrl', e.target.value)} fullWidth />
            <TextField label="Banner URL" value={form.bannerUrl ?? ''} onChange={e => set('bannerUrl', e.target.value)} fullWidth />
            <FormControlLabel control={<Switch checked={!!form.isOpen} onChange={e => set('isOpen', e.target.checked)} color="success" />} label="Shop Open" />
          </Stack>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setOpen(false)}>Cancel</Button>
          <Button variant="contained" onClick={save} disabled={createM.isPending || updateM.isPending}>{editing ? 'Update' : 'Create'}</Button>
        </DialogActions>
      </Dialog>

      <Snackbar open={!!snack} autoHideDuration={3000} onClose={() => setSnack('')} message={snack} anchorOrigin={{ vertical: 'bottom', horizontal: 'right' }} />
    </Box>
  );
}
