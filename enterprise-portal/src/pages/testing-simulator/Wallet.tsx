// @ts-nocheck
import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { Box, Typography, Card, CardContent, Grid, Button, TextField, MenuItem, Chip, Snackbar, Stack, Divider, Alert } from '@mui/material';
import { AccountBalanceWallet, ArrowUpward, ArrowDownward, History } from '@mui/icons-material';
import { getDbSnapshot, adjustWallet } from '../../api/portal';

export default function Wallet() {
  const qc = useQueryClient();
  const { data: db } = useQuery({ queryKey: ['db-snapshot'], queryFn: getDbSnapshot, refetchInterval: 3000 });
  const [amount, setAmount] = useState('10');
  const [op, setOp] = useState<'CREDIT' | 'DEBIT'>('CREDIT');
  const [snack, setSnack] = useState('');

  const adjustM = useMutation({
    mutationFn: () => adjustWallet(parseFloat(amount), op),
    onSuccess: () => { qc.invalidateQueries({ queryKey: ['db-snapshot'] }); setSnack(`${op} of $${amount} applied!`); }
  });

  const balance = db?.user?.walletBalance ?? 0;

  return (
    <Box>
      <Typography variant="h5" fontWeight={700} sx={{ mb: 0.5 }}>Wallet Simulator</Typography>
      <Typography color="text.secondary" fontSize="0.85rem" sx={{ mb: 3 }}>Credit or debit the customer's wallet balance. Changes appear in the app immediately.</Typography>

      <Grid container spacing={3}>
        <Grid item xs={12} md={5}>
          <Card sx={{ background: 'linear-gradient(135deg, rgba(99,102,241,0.15) 0%, rgba(6,182,212,0.15) 100%)', border: '1px solid rgba(99,102,241,0.3)' }}>
            <CardContent sx={{ p: 3 }}>
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 1 }}>
                <AccountBalanceWallet sx={{ color: '#6366f1', fontSize: 28 }} />
                <Typography color="text.secondary" fontSize="0.85rem" fontWeight={600}>CURRENT BALANCE</Typography>
              </Box>
              <Typography variant="h2" sx={{ fontWeight: 900, fontSize: '3rem', color: '#f9fafb', letterSpacing: '-0.03em' }}>
                ${balance.toFixed(2)}
              </Typography>
              <Typography fontSize="0.75rem" color="text.secondary" sx={{ mt: 0.5 }}>
                {db?.user?.name}'s wallet · Auto-refreshes every 3s
              </Typography>
            </CardContent>
          </Card>

          <Card sx={{ mt: 2 }}>
            <CardContent>
              <Typography fontWeight={700} sx={{ mb: 2 }}>Adjust Balance</Typography>
              <Stack spacing={2}>
                <TextField
                  label="Amount ($)"
                  type="number"
                  value={amount}
                  onChange={e => setAmount(e.target.value)}
                  inputProps={{ min: 0.01, step: 0.5 }}
                  fullWidth
                />
                <TextField
                  select label="Operation"
                  value={op}
                  onChange={e => setOp(e.target.value as any)}
                  fullWidth
                >
                  <MenuItem value="CREDIT">💰 CREDIT (Add money)</MenuItem>
                  <MenuItem value="DEBIT">💸 DEBIT (Deduct money)</MenuItem>
                </TextField>
                <Button
                  variant="contained"
                  fullWidth
                  size="large"
                  startIcon={op === 'CREDIT' ? <ArrowUpward /> : <ArrowDownward />}
                  onClick={() => adjustM.mutate()}
                  disabled={adjustM.isPending || !amount}
                  color={op === 'CREDIT' ? 'success' : 'error'}
                  sx={{ py: 1.5 }}
                >
                  Apply {op}
                </Button>
              </Stack>

              {/* Quick amount buttons */}
              <Divider sx={{ my: 2, borderColor: '#1f2937' }} />
              <Typography fontSize="0.78rem" color="text.secondary" sx={{ mb: 1 }}>Quick Amounts</Typography>
              <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 0.8 }}>
                {[5, 10, 25, 50, 100, 200].map(a => (
                  <Chip key={a} label={`$${a}`} onClick={() => setAmount(String(a))} clickable size="small"
                    sx={{ bgcolor: amount === String(a) ? 'rgba(99,102,241,0.2)' : '#1f2937', border: amount === String(a) ? '1px solid #6366f1' : '1px solid #374151' }}
                  />
                ))}
              </Box>
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} md={7}>
          <Card sx={{ height: '100%' }}>
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 2 }}>
                <History sx={{ color: '#9ca3af', fontSize: 18 }} />
                <Typography fontWeight={700}>User Info</Typography>
              </Box>
              {db?.user ? (
                <Stack spacing={1}>
                  {Object.entries(db.user).filter(([k]) => !['profilePhotoUrl','addresses','savedPlaces'].includes(k)).map(([k, v]) => (
                    <Box key={k} sx={{ display: 'flex', justifyContent: 'space-between', py: 0.8, borderBottom: '1px solid #1f2937' }}>
                      <Typography fontSize="0.8rem" color="text.secondary" sx={{ textTransform: 'capitalize' }}>{k}</Typography>
                      <Typography fontSize="0.8rem" fontWeight={k === 'walletBalance' ? 700 : 400} color={k === 'walletBalance' ? '#10b981' : 'text.primary'}>
                        {k === 'walletBalance' ? `$${Number(v).toFixed(2)}` : String(v)}
                      </Typography>
                    </Box>
                  ))}
                </Stack>
              ) : (
                <Alert severity="info">Loading user data…</Alert>
              )}
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      <Snackbar open={!!snack} autoHideDuration={3000} onClose={() => setSnack('')} message={snack} anchorOrigin={{ vertical: 'bottom', horizontal: 'right' }} />
    </Box>
  );
}
