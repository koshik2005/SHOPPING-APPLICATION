// @ts-nocheck
import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import {
  Box, Typography, Button, Grid, Card, CardContent, CardActions, Chip,
  Dialog, DialogTitle, DialogContent, DialogActions, TextField,
  Snackbar, Stack, Alert, Stepper, Step, StepLabel, MenuItem, Divider,
} from '@mui/material';
import { Add, PlayArrow } from '@mui/icons-material';
import { getOrders, createTestOrder, advanceOrderStatus } from '../api/portal';

const STATUSES = ['PENDING', 'ACCEPTED', 'PREPARING', 'PACKED', 'READY', 'PICKED_UP', 'IN_TRANSIT', 'DELIVERED'];
const CANCEL_STATUSES = ['CANCELLED', 'REFUNDED'];
const ALL_STATUSES = [...STATUSES, ...CANCEL_STATUSES];

const STATUS_COLORS: Record<string, 'default'|'primary'|'secondary'|'info'|'success'|'warning'|'error'> = {
  PENDING: 'warning', ACCEPTED: 'info', PREPARING: 'info', PACKED: 'info',
  READY: 'primary', PICKED_UP: 'secondary', IN_TRANSIT: 'secondary',
  DELIVERED: 'success', CANCELLED: 'error', REFUNDED: 'error',
};

export default function Orders() {
  const qc = useQueryClient();
  const { data: orders = [] } = useQuery({ queryKey: ['orders'], queryFn: getOrders, refetchInterval: 5000 });
  const [createOpen, setCreateOpen] = useState(false);
  const [form, setForm] = useState({ totalPrice: 99.0, deliveryFee: 2.5, items: [] as any[] });
  const [snack, setSnack] = useState('');

  const createM = useMutation({ mutationFn: createTestOrder, onSuccess: () => { qc.invalidateQueries({ queryKey: ['orders'] }); setCreateOpen(false); setSnack('Test order created!'); } });
  const advanceM = useMutation({ mutationFn: ({ orderId, status }: any) => advanceOrderStatus(orderId, status), onSuccess: () => { qc.invalidateQueries({ queryKey: ['orders'] }); setSnack('Order status updated!'); } });

  const stepIndex = (status: string) => STATUSES.indexOf(status);

  return (
    <Box>
      <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 3 }}>
        <Box>
          <Typography variant="h5" fontWeight={700}>Order Simulator</Typography>
          <Typography color="text.secondary" fontSize="0.85rem">Create test orders and step them through the full lifecycle state machine.</Typography>
        </Box>
        <Button variant="contained" startIcon={<Add />} onClick={() => setCreateOpen(true)}>Create Test Order</Button>
      </Box>

      {orders.length === 0 && (
        <Alert severity="info" sx={{ mb: 2 }}>No orders. Create a test order to simulate the customer app's order tracking flow.</Alert>
      )}

      <Stack spacing={2}>
        {[...orders].reverse().map((o: any) => {
          const isTerminal = CANCEL_STATUSES.includes(o.status);
          const step = isTerminal ? -1 : stepIndex(o.status);
          return (
            <Card key={o.id}>
              <CardContent>
                <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 2 }}>
                  <Box>
                    <Typography fontWeight={700}>Order #{o.id}</Typography>
                    <Typography fontSize="0.78rem" color="text.secondary">{o.createdAt}</Typography>
                  </Box>
                  <Box sx={{ textAlign: 'right' }}>
                    <Chip label={o.status} size="small" color={STATUS_COLORS[o.status] ?? 'default'} sx={{ fontWeight: 700 }} />
                    <Typography fontWeight={700} sx={{ mt: 0.5 }}>${o.totalPrice?.toFixed(2)}</Typography>
                  </Box>
                </Box>

                {!isTerminal && (
                  <Box sx={{ mb: 2 }}>
                    <Stepper activeStep={step} alternativeLabel sx={{ '& .MuiStepLabel-label': { fontSize: '0.6rem' } }}>
                      {STATUSES.map(s => (
                        <Step key={s} completed={stepIndex(o.status) > stepIndex(s)}>
                          <StepLabel sx={{ '& .MuiStepLabel-label.Mui-active': { color: '#6366f1', fontWeight: 700 } }}>
                            {s.replace('_', ' ')}
                          </StepLabel>
                        </Step>
                      ))}
                    </Stepper>
                  </Box>
                )}

                {/* Status buttons */}
                <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 1 }}>
                  {ALL_STATUSES.filter(s => s !== o.status).map(s => (
                    <Button
                      key={s}
                      size="small"
                      variant={STATUSES.indexOf(s) === step + 1 ? 'contained' : 'outlined'}
                      color={CANCEL_STATUSES.includes(s) ? 'error' : 'primary'}
                      startIcon={<PlayArrow />}
                      onClick={() => advanceM.mutate({ orderId: o.id, status: s })}
                    >
                      → {s.replace('_', ' ')}
                    </Button>
                  ))}
                </Box>

                {o.history?.length > 0 && (
                  <Box sx={{ mt: 1.5 }}>
                    <Typography fontSize="0.72rem" color="text.secondary" fontWeight={700} sx={{ mb: 0.5 }}>HISTORY</Typography>
                    {o.history.slice(-3).map((h: any, i: number) => (
                      <Typography key={i} fontSize="0.7rem" color="text.secondary">
                        {h.timestamp?.slice(11, 19)} · {h.status} {h.remarks && `— ${h.remarks}`}
                      </Typography>
                    ))}
                  </Box>
                )}
              </CardContent>
            </Card>
          );
        })}
      </Stack>

      {/* Create dialog */}
      <Dialog open={createOpen} onClose={() => setCreateOpen(false)} maxWidth="xs" fullWidth>
        <DialogTitle>Create Test Order</DialogTitle>
        <DialogContent>
          <Stack spacing={2} sx={{ mt: 1 }}>
            <TextField label="Total Price ($)" type="number" value={form.totalPrice} onChange={e => setForm(f => ({ ...f, totalPrice: parseFloat(e.target.value) }))} fullWidth />
            <TextField label="Delivery Fee ($)" type="number" value={form.deliveryFee} onChange={e => setForm(f => ({ ...f, deliveryFee: parseFloat(e.target.value) }))} fullWidth />
          </Stack>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setCreateOpen(false)}>Cancel</Button>
          <Button variant="contained" onClick={() => createM.mutate(form)} disabled={createM.isPending}>Create</Button>
        </DialogActions>
      </Dialog>

      <Snackbar open={!!snack} autoHideDuration={3000} onClose={() => setSnack('')} message={snack} anchorOrigin={{ vertical: 'bottom', horizontal: 'right' }} />
    </Box>
  );
}
