// @ts-nocheck
import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import {
  Box, Typography, Card, CardContent, Stack, Chip, Button, MenuItem, TextField,
  Snackbar, Alert, Table, TableHead, TableBody, TableRow, TableCell, Paper,
} from '@mui/material';
import { Payment, CheckCircle, Cancel, HourglassEmpty, Schedule, Replay } from '@mui/icons-material';
import { getOrders, injectPayment } from '../../api/portal';

const RESULTS = [
  { value: 'SUCCESS',  label: '✅ SUCCESS',  color: '#10b981', icon: <CheckCircle /> },
  { value: 'FAILED',   label: '❌ FAILED',   color: '#ef4444', icon: <Cancel /> },
  { value: 'PENDING',  label: '⏳ PENDING',  color: '#f59e0b', icon: <HourglassEmpty /> },
  { value: 'TIMEOUT',  label: '⏰ TIMEOUT',  color: '#f59e0b', icon: <Schedule /> },
  { value: 'REFUNDED', label: '♻️ REFUNDED', color: '#6366f1', icon: <Replay /> },
];

export default function Payments() {
  const qc = useQueryClient();
  const { data: orders = [] } = useQuery({ queryKey: ['orders'], queryFn: getOrders, refetchInterval: 5000 });
  const [selected, setSelected] = useState('');
  const [result, setResult] = useState('SUCCESS');
  const [snack, setSnack] = useState('');

  const injectM = useMutation({
    mutationFn: () => injectPayment(selected, result),
    onSuccess: () => { qc.invalidateQueries({ queryKey: ['orders'] }); setSnack(`Payment ${result} injected!`); }
  });

  return (
    <Box>
      <Typography variant="h5" fontWeight={700} sx={{ mb: 0.5 }}>Payment Simulator</Typography>
      <Typography color="text.secondary" fontSize="0.85rem" sx={{ mb: 3 }}>Inject payment outcomes (SUCCESS, FAILED, TIMEOUT, REFUNDED) for any existing order.</Typography>

      <Stack direction={{ xs: 'column', md: 'row' }} spacing={3}>
        {/* Inject panel */}
        <Card sx={{ minWidth: 320, flex: '0 0 auto' }}>
          <CardContent>
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 2 }}>
              <Payment sx={{ color: '#6366f1' }} />
              <Typography fontWeight={700}>Inject Payment Event</Typography>
            </Box>
            <Stack spacing={2}>
              <TextField
                select label="Select Order"
                value={selected}
                onChange={e => setSelected(e.target.value)}
                fullWidth
              >
                {orders.length === 0 ? (
                  <MenuItem disabled>No orders — create one first</MenuItem>
                ) : (
                  orders.map((o: any) => (
                    <MenuItem key={o.id} value={o.id}>
                      #{o.id} · ${o.totalPrice} · {o.status}
                    </MenuItem>
                  ))
                )}
              </TextField>

              <Box>
                <Typography fontSize="0.8rem" color="text.secondary" sx={{ mb: 1 }}>Payment Result</Typography>
                <Stack spacing={0.8}>
                  {RESULTS.map(r => (
                    <Box
                      key={r.value}
                      onClick={() => setResult(r.value)}
                      sx={{
                        display: 'flex', alignItems: 'center', gap: 1.5, p: 1.5,
                        borderRadius: 2, cursor: 'pointer', border: '1px solid',
                        borderColor: result === r.value ? r.color : '#1f2937',
                        bgcolor: result === r.value ? `${r.color}15` : 'transparent',
                        transition: 'all 0.15s',
                        '&:hover': { borderColor: r.color },
                      }}
                    >
                      <Box sx={{ color: r.color, display: 'flex' }}>{r.icon}</Box>
                      <Typography fontWeight={result === r.value ? 700 : 400} fontSize="0.85rem">{r.label}</Typography>
                    </Box>
                  ))}
                </Stack>
              </Box>

              <Button
                variant="contained" fullWidth size="large"
                onClick={() => injectM.mutate()}
                disabled={!selected || injectM.isPending}
                sx={{ py: 1.5 }}
              >
                Inject {result}
              </Button>
            </Stack>
          </CardContent>
        </Card>

        {/* Orders table */}
        <Box sx={{ flex: 1 }}>
          <Paper>
            <Table size="small">
              <TableHead>
                <TableRow>
                  <TableCell>Order ID</TableCell>
                  <TableCell align="right">Amount</TableCell>
                  <TableCell>Status</TableCell>
                  <TableCell>Payment</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {orders.length === 0 && (
                  <TableRow><TableCell colSpan={4} align="center" sx={{ py: 4, color: '#4b5563' }}>No orders yet</TableCell></TableRow>
                )}
                {[...orders].reverse().map((o: any) => (
                  <TableRow key={o.id} sx={{ cursor: 'pointer', '&:hover': { bgcolor: 'rgba(99,102,241,0.05)' } }} onClick={() => setSelected(o.id)}>
                    <TableCell><Typography fontSize="0.8rem" fontFamily="monospace">#{o.id}</Typography></TableCell>
                    <TableCell align="right"><Typography fontWeight={600} fontSize="0.85rem">${o.totalPrice}</Typography></TableCell>
                    <TableCell><Chip label={o.status} size="small" /></TableCell>
                    <TableCell>
                      {o.paymentStatus ? (
                        <Chip label={o.paymentStatus} size="small" color={o.paymentStatus === 'SUCCESS' ? 'success' : o.paymentStatus === 'FAILED' ? 'error' : 'warning'} />
                      ) : (
                        <Chip label="Not set" size="small" variant="outlined" />
                      )}
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </Paper>
        </Box>
      </Stack>

      <Snackbar open={!!snack} autoHideDuration={3000} onClose={() => setSnack('')} message={snack} anchorOrigin={{ vertical: 'bottom', horizontal: 'right' }} />
    </Box>
  );
}
