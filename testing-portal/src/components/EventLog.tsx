// @ts-nocheck
import React, { useEffect, useRef, useState } from 'react';
import { Box, Typography, Chip } from '@mui/material';

interface LogEvent {
  id: string;
  type: string;
  action: string;
  payload: any;
  ts: string;
}

const TYPE_COLORS: Record<string, string> = {
  ORDER: '#6366f1',
  BRANCH: '#06b6d4',
  SHOP: '#10b981',
  CATEGORY: '#f59e0b',
  PRODUCT: '#8b5cf6',
  INVENTORY: '#f59e0b',
  DELIVERY: '#06b6d4',
  WALLET: '#10b981',
  PAYMENT: '#6366f1',
  NOTIFICATION: '#3b82f6',
  BANNER: '#ec4899',
  OFFER: '#f59e0b',
  CONFIG: '#9ca3af',
  USER: '#10b981',
  PERMISSION: '#ef4444',
  DEFAULT: '#4b5563',
};

export default function EventLog({ maxHeight = 420 }: { maxHeight?: number }) {
  const [events, setEvents] = useState<LogEvent[]>([]);
  const [connected, setConnected] = useState(false);
  const bottomRef = useRef<HTMLDivElement>(null);
  const esRef = useRef<EventSource | null>(null);

  useEffect(() => {
    const es = new EventSource('/api/portal/events');
    esRef.current = es;

    es.onopen = () => setConnected(true);
    es.onerror = () => setConnected(false);
    es.onmessage = (e) => {
      try {
        const ev: LogEvent = JSON.parse(e.data);
        setEvents(prev => [...prev.slice(-199), ev]);
      } catch {}
    };

    return () => { es.close(); setConnected(false); };
  }, []);

  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [events]);

  const color = (type: string) => TYPE_COLORS[type] ?? TYPE_COLORS.DEFAULT;

  return (
    <Box>
      <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 1.5 }}>
        <Box sx={{ width: 8, height: 8, borderRadius: '50%', bgcolor: connected ? '#10b981' : '#ef4444', animation: connected ? 'pulse 2s infinite' : 'none', '@keyframes pulse': { '0%,100%': { opacity: 1 }, '50%': { opacity: 0.4 } } }} />
        <Typography sx={{ fontSize: '0.75rem', color: '#9ca3af' }}>
          {connected ? 'SSE Connected' : 'Disconnected'} · {events.length} events
        </Typography>
      </Box>
      <Box
        sx={{
          maxHeight, overflowY: 'auto', fontFamily: "'JetBrains Mono', 'Fira Code', monospace",
          fontSize: '0.72rem', bgcolor: '#0a0f1e', border: '1px solid #1f2937',
          borderRadius: 2, p: 1.5,
        }}
      >
        {events.length === 0 && (
          <Typography sx={{ color: '#374151', textAlign: 'center', py: 4, fontSize: '0.75rem' }}>
            Waiting for events… Perform any simulation action to see live events here.
          </Typography>
        )}
        {events.map((ev, i) => (
          <Box key={`${ev.id}-${i}`} sx={{ display: 'flex', gap: 1.5, py: 0.4, borderBottom: '1px solid #0d1525', alignItems: 'flex-start' }}>
            <Typography sx={{ color: '#4b5563', whiteSpace: 'nowrap', lineHeight: 1.6, minWidth: 80, fontSize: '0.65rem' }}>
              {ev.ts?.slice(11, 19) ?? ''}
            </Typography>
            <Box sx={{ display: 'flex', gap: 0.8, alignItems: 'center', minWidth: 120 }}>
              <Box sx={{ width: 8, height: 8, borderRadius: '50%', bgcolor: color(ev.type), flexShrink: 0 }} />
              <Typography sx={{ color: color(ev.type), fontWeight: 700, fontSize: '0.68rem', letterSpacing: '0.04em' }}>
                {ev.type}
              </Typography>
              <Typography sx={{ color: '#9ca3af', fontSize: '0.65rem' }}>·</Typography>
              <Typography sx={{ color: '#d1d5db', fontSize: '0.68rem' }}>{ev.action}</Typography>
            </Box>
            <Typography sx={{ color: '#6b7280', fontSize: '0.65rem', wordBreak: 'break-all', flex: 1 }}>
              {JSON.stringify(ev.payload)}
            </Typography>
          </Box>
        ))}
        <div ref={bottomRef} />
      </Box>
    </Box>
  );
}
