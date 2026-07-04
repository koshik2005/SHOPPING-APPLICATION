// @ts-nocheck
import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import {
  Box, Typography, Button, Grid, Card, CardContent, CardActions, Chip, IconButton,
  Dialog, DialogTitle, DialogContent, DialogActions, TextField, Switch, FormControlLabel,
  Alert, Snackbar, Divider, Stack,
} from '@mui/material';
import { Add, Edit, Delete, PowerSettingsNew, LocationOn } from '@mui/icons-material';
import { getBranches, createBranch, updateBranch, deleteBranch } from '../api/portal';

const EMPTY = { name: '', address: '', workingHours: '08:00 AM - 10:00 PM', latitude: 37.7749, longitude: -122.4194, servingRadiusKm: 5, deliveryFee: 2.5, taxRate: 0.08, isOpen: true };

export default function Branches() {
  const qc = useQueryClient();
  const { data: branches = [], isLoading } = useQuery({ queryKey: ['branches'], queryFn: getBranches });
  const [open, setOpen] = useState(false);
  const [form, setForm] = useState<any>(EMPTY);
  const [editing, setEditing] = useState(false);
  const [snack, setSnack] = useState('');

  const createM = useMutation({ mutationFn: createBranch, onSuccess: () => { qc.invalidateQueries({ queryKey: ['branches'] }); setOpen(false); setSnack('Branch created!'); } });
  const updateM = useMutation({ mutationFn: updateBranch, onSuccess: () => { qc.invalidateQueries({ queryKey: ['branches'] }); setOpen(false); setSnack('Branch updated!'); } });
  const deleteM = useMutation({ mutationFn: deleteBranch, onSuccess: () => { qc.invalidateQueries({ queryKey: ['branches'] }); setSnack('Branch deleted!'); } });

  const openCreate = () => { setForm(EMPTY); setEditing(false); setOpen(true); };
  const openEdit = (b: any) => { setForm({ ...b }); setEditing(true); setOpen(true); };
  const save = () => editing ? updateM.mutate(form) : createM.mutate(form);
  const set = (k: string, v: any) => setForm((f: any) => ({ ...f, [k]: v }));

  return (
    <Box>
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
        <Box>
          <Typography variant="h5" fontWeight={700}>Branch Simulator</Typography>
          <Typography color="text.secondary" fontSize="0.85rem">Create and manage delivery branches. Changes instantly reflect in the customer app.</Typography>
        </Box>
        <Button variant="contained" startIcon={<Add />} onClick={openCreate}>New Branch</Button>
      </Box>

      {branches.length === 0 && !isLoading && (
        <Alert severity="info" sx={{ mb: 2 }}>No branches configured. Create the first one!</Alert>
      )}

      <Grid container spacing={2}>
        {branches.map((b: any) => (
          <Grid item xs={12} md={6} lg={4} key={b.id}>
            <Card>
              <CardContent>
                <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 1 }}>
                  <Typography fontWeight={700}>{b.name || b.id}</Typography>
                  <Chip label={b.isOpen ? 'OPEN' : 'CLOSED'} size="small" color={b.isOpen ? 'success' : 'error'} />
                </Box>
                <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5, mb: 0.5 }}>
                  <LocationOn sx={{ fontSize: 14, color: '#6b7280' }} />
                  <Typography fontSize="0.8rem" color="text.secondary">{b.address || 'No address set'}</Typography>
                </Box>
                <Typography fontSize="0.78rem" color="text.secondary">🕒 {b.workingHours}</Typography>
                <Typography fontSize="0.78rem" color="text.secondary">📡 Radius: {b.servingRadiusKm} km · Fee: ${b.deliveryFee}</Typography>
                {b.categories?.length > 0 && <Typography fontSize="0.78rem" color="text.secondary">🗂 {b.categories.length} categories · {b.products?.length ?? 0} products</Typography>}
              </CardContent>
              <CardActions sx={{ px: 2, pb: 2, gap: 1 }}>
                <Button size="small" startIcon={<Edit />} onClick={() => openEdit(b)} variant="outlined">Edit</Button>
                <Button size="small" startIcon={<Delete />} onClick={() => deleteM.mutate(b.id)} color="error" variant="outlined">Delete</Button>
                <Button size="small" startIcon={<PowerSettingsNew />} onClick={() => updateM.mutate({ id: b.id, isOpen: !b.isOpen })} variant="outlined" color={b.isOpen ? 'warning' : 'success'}>
                  {b.isOpen ? 'Close' : 'Open'}
                </Button>
              </CardActions>
            </Card>
          </Grid>
        ))}
      </Grid>

      {/* Dialog */}
      <Dialog open={open} onClose={() => setOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle>{editing ? 'Edit Branch' : 'Create New Branch'}</DialogTitle>
        <DialogContent>
          <Stack spacing={2} sx={{ mt: 1 }}>
            <TextField label="Branch Name" value={form.name ?? ''} onChange={e => set('name', e.target.value)} fullWidth />
            <TextField label="Address" value={form.address ?? ''} onChange={e => set('address', e.target.value)} fullWidth />
            <TextField label="Working Hours" value={form.workingHours ?? ''} onChange={e => set('workingHours', e.target.value)} fullWidth />
            <Grid container spacing={2}>
              <Grid item xs={6}><TextField label="Latitude" type="number" value={form.latitude ?? ''} onChange={e => set('latitude', parseFloat(e.target.value))} fullWidth /></Grid>
              <Grid item xs={6}><TextField label="Longitude" type="number" value={form.longitude ?? ''} onChange={e => set('longitude', parseFloat(e.target.value))} fullWidth /></Grid>
            </Grid>
            <Grid container spacing={2}>
              <Grid item xs={4}><TextField label="Radius (km)" type="number" value={form.servingRadiusKm ?? ''} onChange={e => set('servingRadiusKm', parseFloat(e.target.value))} fullWidth /></Grid>
              <Grid item xs={4}><TextField label="Delivery Fee ($)" type="number" value={form.deliveryFee ?? ''} onChange={e => set('deliveryFee', parseFloat(e.target.value))} fullWidth /></Grid>
              <Grid item xs={4}><TextField label="Tax Rate" type="number" value={form.taxRate ?? ''} onChange={e => set('taxRate', parseFloat(e.target.value))} fullWidth /></Grid>
            </Grid>
            <FormControlLabel control={<Switch checked={!!form.isOpen} onChange={e => set('isOpen', e.target.checked)} color="success" />} label="Branch Open" />
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
