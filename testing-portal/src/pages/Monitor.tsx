// @ts-nocheck
import React from 'react';
import { Box, Typography, Chip, Divider } from '@mui/material';
import EventLog from '../components/EventLog';

export default function Monitor() {
  return (
    <Box>
      <Box sx={{ mb: 3 }}>
        <Typography variant="h5" fontWeight={700}>Live Event Monitor</Typography>
        <Typography color="text.secondary" fontSize="0.85rem" sx={{ mb: 1 }}>
          Real-time stream of all simulation actions via Server-Sent Events. Every write to database.json is broadcast here.
        </Typography>
        <Box sx={{ display: 'flex', gap: 1, flexWrap: 'wrap' }}>
          {['ORDER', 'BRANCH', 'PRODUCT', 'INVENTORY', 'DELIVERY', 'WALLET', 'PAYMENT', 'NOTIFICATION', 'BANNER', 'OFFER', 'CONFIG'].map(t => (
            <Chip key={t} label={t} size="small" sx={{ fontSize: '0.65rem', fontWeight: 700, bgcolor: '#1f2937', border: '1px solid #374151' }} />
          ))}
        </Box>
      </Box>

      <EventLog maxHeight={600} />

      <Box sx={{ mt: 2, p: 2, bgcolor: '#0d1525', borderRadius: 2, border: '1px solid #1f2937' }}>
        <Typography fontWeight={600} fontSize="0.8rem" sx={{ mb: 1 }}>How it works</Typography>
        <Typography fontSize="0.78rem" color="text.secondary">
          Each simulation action in any module (creating products, advancing orders, crediting wallets) calls a <code style={{ color: '#818cf8', background: '#0a0f1e', padding: '1px 4px', borderRadius: 3 }}>broadcast_event()</code> function in server.py. 
          This function pushes a structured JSON event to all active SSE connections.
          This view connects to <code style={{ color: '#818cf8', background: '#0a0f1e', padding: '1px 4px', borderRadius: 3 }}>/api/portal/events</code> and streams them live.
          The last 50 events are replayed on reconnection.
        </Typography>
      </Box>
    </Box>
  );
}
