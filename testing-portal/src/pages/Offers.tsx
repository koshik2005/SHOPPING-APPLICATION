// @ts-nocheck
import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import {
  Box, Typography, Button, Card, CardContent, CardActions, Grid, Chip,
  Dialog, DialogTitle, DialogContent, DialogActions, TextField, MenuItem,
  Snackbar, Stack, Switch, FormControlLabel, Alert, Divider,
} from '@mui/material';
import { Add, Delete, ToggleOff, ToggleOn } from '@mui/icons-material';
import { getOffers, createOffer, toggleOffer, deleteOffer } from '../api/portal';

const OFFER_TYPES = ['COUPON', 'FLASH_SALE', 'CASHBACK', 'FREE_DELIVERY', 'BOGO'];
const DISCOUNT_TYPES = ['PERCENT', 'FLAT'];
const EMPTY = { type: 'COUPON', code: '', title: '', discountType: 'PERCENT', discountValue: 10, minOrderValue: 0, maxDiscount: '', expiresAt: '', isActive: true };

const TYPE_EMOJI: Record<string, string> = { COUPON: '🎟', FLASH_SALE: '⚡', CASHBACK: '💰', FREE_DELIVERY: '🚚', BOGO: '2️⃣' };

export default function Offers() {
  const qc = useQueryClient();
  const { data: offers = [] } = useQuery({ queryKey: ['offers'], queryFn: getOffers });
  const [open, setOpen] = useState(false);
  const [form, setForm] = useState<any>(EMPTY);
  const [snack, setSnack] = useState('');

  const createM = useMutation({ mutationFn: createOffer, onSuccess: () => { qc.invalidateQueries({ queryKey: ['offers'] }); setOpen(false); setSnack('Offer created!'); } });
  const toggleM = useMutation({ mutationFn: toggleOffer, onSuccess: () => { qc.invalidateQueries({ queryKey: ['offers'] }); setSnack('Offer toggled!'); } });
  const deleteM = useMutation({ mutationFn: deleteOffer, onSuccess: () => { qc.invalidateQueries({ queryKey: ['offers'] }); setSnack('Offer deleted!'); } });

  const set = (k: string, v: any) => setForm((f: any) => ({ ...f, [k]: v }));

  return (
    <Box>
      <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 3 }}>
        <Box>
          <Typography variant="h5" fontWeight={700}>Offers & Coupons Simulator</Typography>
          <Typography color="text.secondary" fontSize="0.85rem">Create discount coupons, cashback, flash sales, and free delivery offers for testing.</Typography>
        </Box>
        <Button variant="contained" startIcon={<Add />} onClick={() => { setForm(EMPTY); setOpen(true); }}>New Offer</Button>
      </Box>

      {offers.length === 0 && (
        <Alert severity="info" sx={{ mb: 2 }}>No offers. Create a coupon to test the customer app's checkout discount flow.</Alert>
      )}

      <Grid container spacing={2}>
        {offers.map((o: any) => (
          <Grid item xs={12} sm={6} md={4} key={o.id}>
            <Card sx={{ opacity: o.isActive ? 1 : 0.5, background: o.isActive ? 'linear-gradient(135deg, rgba(99,102,241,0.08), rgba(6,182,212,0.05))' : undefined }}>
              <CardContent>
                <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 1 }}>
                  <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                    <Typography fontSize="1.5rem">{TYPE_EMOJI[o.type] ?? '🎁'}</Typography>
                    <Box>
                      <Typography fontWeight={700} fontSize="0.95rem">{o.code || o.title}</Typography>
                      <Chip label={o.type} size="small" />
                    </Box>
                  </Box>
                  <Chip label={o.isActive ? 'ACTIVE' : 'OFF'} size="small" color={o.isActive ? 'success' : 'default'} />
                </Box>

                <Box sx={{ p: 1.5, bgcolor: '#0d1525', borderRadius: 2, mb: 1 }}>
                  <Typography fontWeight={700} fontSize="1.2rem" color="primary.light">
                    {o.discountType === 'PERCENT' ? `${o.discountValue}% OFF` : `$${o.discountValue} OFF`}
                  </Typography>
                  {o.minOrderValue > 0 && <Typography fontSize="0.72rem" color="text.secondary">Min. order: ${o.minOrderValue}</Typography>}
                  {o.maxDiscount && <Typography fontSize="0.72rem" color="text.secondary">Max discount: ${o.maxDiscount}</Typography>}
                </Box>

                <Typography fontWeight={500} fontSize="0.82rem" color="text.secondary">{o.title}</Typography>
                {o.expiresAt && <Typography fontSize="0.72rem" color="warning.main" sx={{ mt: 0.5 }}>⏰ Expires: {o.expiresAt}</Typography>}
              </CardContent>
              <CardActions sx={{ px: 2, pb: 2 }}>
                <Button size="small" startIcon={o.isActive ? <ToggleOff /> : <ToggleOn />} onClick={() => toggleM.mutate(o.id)} variant="outlined" color={o.isActive ? 'warning' : 'success'}>
                  {o.isActive ? 'Deactivate' : 'Activate'}
                </Button>
                <Button size="small" startIcon={<Delete />} onClick={() => deleteM.mutate(o.id)} color="error" variant="outlined">Delete</Button>
              </CardActions>
            </Card>
          </Grid>
        ))}
      </Grid>

      <Dialog open={open} onClose={() => setOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle>Create Offer</DialogTitle>
        <DialogContent>
          <Stack spacing={2} sx={{ mt: 1 }}>
            <TextField select label="Offer Type" value={form.type} onChange={e => set('type', e.target.value)} fullWidth>
              {OFFER_TYPES.map(t => <MenuItem key={t} value={t}>{TYPE_EMOJI[t]} {t}</MenuItem>)}
            </TextField>
            <TextField label="Coupon Code (e.g. SAVE10)" value={form.code} onChange={e => set('code', e.target.value.toUpperCase())} fullWidth />
            <TextField label="Offer Title / Description" value={form.title} onChange={e => set('title', e.target.value)} fullWidth required />
            <Grid container spacing={2}>
              <Grid item xs={6}>
                <TextField select label="Discount Type" value={form.discountType} onChange={e => set('discountType', e.target.value)} fullWidth>
                  {DISCOUNT_TYPES.map(t => <MenuItem key={t} value={t}>{t}</MenuItem>)}
                </TextField>
              </Grid>
              <Grid item xs={6}>
                <TextField label="Value" type="number" value={form.discountValue} onChange={e => set('discountValue', parseFloat(e.target.value))} fullWidth helperText={form.discountType === 'PERCENT' ? '%' : '$'} />
              </Grid>
            </Grid>
            <Grid container spacing={2}>
              <Grid item xs={6}><TextField label="Min. Order ($)" type="number" value={form.minOrderValue} onChange={e => set('minOrderValue', parseFloat(e.target.value))} fullWidth /></Grid>
              <Grid item xs={6}><TextField label="Max Discount ($)" type="number" value={form.maxDiscount ?? ''} onChange={e => set('maxDiscount', e.target.value || null)} fullWidth /></Grid>
            </Grid>
            <TextField label="Expires At (e.g. 2025-12-31)" value={form.expiresAt} onChange={e => set('expiresAt', e.target.value)} fullWidth />
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
