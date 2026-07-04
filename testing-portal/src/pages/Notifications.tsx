// @ts-nocheck
import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import {
  Box, Typography, Button, Card, CardContent, Stack, TextField, MenuItem,
  Chip, Snackbar, Alert, Grid, Divider, Table, TableHead, TableBody, TableRow, TableCell, Paper,
} from '@mui/material';
import { Send, Notifications as NotifIcon } from '@mui/icons-material';
import { getNotifications, sendNotification } from '../api/portal';

const TYPES = [
  { value: 'ORDER_UPDATE', label: '📦 Order Update', color: '#6366f1' },
  { value: 'PROMO', label: '🎉 Promotion', color: '#10b981' },
  { value: 'ALERT', label: '⚠️ Alert', color: '#f59e0b' },
  { value: 'INFO', label: 'ℹ️ Info', color: '#3b82f6' },
  { value: 'WALLET', label: '💰 Wallet', color: '#10b981' },
  { value: 'SYSTEM', label: '🔧 System', color: '#9ca3af' },
];

export default function Notifications() {
  const qc = useQueryClient();
  const { data: history = [] } = useQuery({ queryKey: ['notifications'], queryFn: getNotifications, refetchInterval: 5000 });
  const [form, setForm] = useState({ type: 'ORDER_UPDATE', title: '', body: '', targetType: 'ALL' });
  const [snack, setSnack] = useState('');

  const sendM = useMutation({
    mutationFn: () => sendNotification(form),
    onSuccess: () => { qc.invalidateQueries({ queryKey: ['notifications'] }); setSnack('Notification sent!'); setForm(f => ({ ...f, title: '', body: '' })); }
  });

  const set = (k: string, v: string) => setForm(f => ({ ...f, [k]: v }));
  const typeInfo = TYPES.find(t => t.value === form.type);

  return (
    <Box>
      <Typography variant="h5" fontWeight={700} sx={{ mb: 0.5 }}>Notification Simulator</Typography>
      <Typography color="text.secondary" fontSize="0.85rem" sx={{ mb: 3 }}>Send simulated push notifications. They are logged to the event monitor and database.</Typography>

      <Grid container spacing={3}>
        <Grid item xs={12} md={5}>
          <Card>
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 2 }}>
                <NotifIcon sx={{ color: '#6366f1' }} />
                <Typography fontWeight={700}>Compose Notification</Typography>
              </Box>
              <Stack spacing={2}>
                <Box>
                  <Typography fontSize="0.8rem" color="text.secondary" sx={{ mb: 1 }}>Notification Type</Typography>
                  <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 0.8 }}>
                    {TYPES.map(t => (
                      <Chip
                        key={t.value} label={t.label} clickable
                        onClick={() => set('type', t.value)}
                        sx={{ bgcolor: form.type === t.value ? `${t.color}20` : '#1f2937', border: `1px solid ${form.type === t.value ? t.color : '#374151'}`, color: form.type === t.value ? t.color : '#9ca3af', fontWeight: form.type === t.value ? 700 : 400 }}
                      />
                    ))}
                  </Box>
                </Box>

                <TextField label="Title" value={form.title} onChange={e => set('title', e.target.value)} fullWidth required />
                <TextField label="Message Body" value={form.body} onChange={e => set('body', e.target.value)} fullWidth multiline rows={3} required />
                <TextField select label="Target Audience" value={form.targetType} onChange={e => set('targetType', e.target.value)} fullWidth>
                  <MenuItem value="ALL">All Users</MenuItem>
                  <MenuItem value="CUSTOMERS">Customers only</MenuItem>
                  <MenuItem value="PARTNERS">Delivery Partners</MenuItem>
                  <MenuItem value="TEST">Test Device</MenuItem>
                </TextField>

                {/* Preview */}
                {(form.title || form.body) && (
                  <Box sx={{ p: 2, bgcolor: '#0d1525', borderRadius: 2, border: '1px solid #1f2937' }}>
                    <Typography fontSize="0.72rem" color="text.secondary" sx={{ mb: 0.5 }}>PREVIEW</Typography>
                    <Box sx={{ display: 'flex', gap: 1.5, alignItems: 'flex-start' }}>
                      <Box sx={{ width: 36, height: 36, borderRadius: 2, bgcolor: `${typeInfo?.color}20`, display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0, fontSize: '1.2rem' }}>
                        {TYPES.find(t => t.value === form.type)?.label.split(' ')[0] ?? '📢'}
                      </Box>
                      <Box>
                        <Typography fontWeight={700} fontSize="0.85rem">{form.title || 'Notification Title'}</Typography>
                        <Typography fontSize="0.78rem" color="text.secondary">{form.body || 'Notification body message...'}</Typography>
                        <Typography fontSize="0.68rem" color="text.disabled" sx={{ mt: 0.3 }}>Now · HyperLocal</Typography>
                      </Box>
                    </Box>
                  </Box>
                )}

                <Button variant="contained" fullWidth size="large" startIcon={<Send />} onClick={() => sendM.mutate()} disabled={!form.title || !form.body || sendM.isPending}>
                  Send Notification
                </Button>
              </Stack>
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} md={7}>
          <Paper>
            <Box sx={{ p: 2, borderBottom: '1px solid #1f2937' }}>
              <Typography fontWeight={700}>Notification History ({history.length})</Typography>
            </Box>
            <Table size="small">
              <TableHead>
                <TableRow>
                  <TableCell>Time</TableCell>
                  <TableCell>Type</TableCell>
                  <TableCell>Title</TableCell>
                  <TableCell>Target</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {history.length === 0 && <TableRow><TableCell colSpan={4} align="center" sx={{ py: 3, color: '#4b5563' }}>No notifications sent yet</TableCell></TableRow>}
                {[...history].reverse().map((n: any) => {
                  const t = TYPES.find(t => t.value === n.type);
                  return (
                    <TableRow key={n.id}>
                      <TableCell><Typography fontSize="0.72rem" color="text.secondary">{n.sentAt?.slice(11, 19)}</Typography></TableCell>
                      <TableCell><Chip label={n.type} size="small" sx={{ bgcolor: `${t?.color ?? '#6b7280'}20`, color: t?.color ?? '#9ca3af', fontSize: '0.65rem' }} /></TableCell>
                      <TableCell>
                        <Typography fontSize="0.8rem" fontWeight={600}>{n.title}</Typography>
                        <Typography fontSize="0.72rem" color="text.secondary">{n.body}</Typography>
                      </TableCell>
                      <TableCell><Chip label={n.targetType} size="small" /></TableCell>
                    </TableRow>
                  );
                })}
              </TableBody>
            </Table>
          </Paper>
        </Grid>
      </Grid>

      <Snackbar open={!!snack} autoHideDuration={3000} onClose={() => setSnack('')} message={snack} anchorOrigin={{ vertical: 'bottom', horizontal: 'right' }} />
    </Box>
  );
}
