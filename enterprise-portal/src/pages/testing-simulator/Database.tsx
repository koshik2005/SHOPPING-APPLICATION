// @ts-nocheck
import React, { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { Box, Typography, TextField, Paper, Chip, Alert, CircularProgress } from '@mui/material';
import { getDbSnapshot } from '../../api/portal';

function JsonNode({ data, depth = 0 }: { data: any; depth?: number }) {
  const [collapsed, setCollapsed] = useState(depth > 1);

  if (data === null) return <span style={{ color: '#9ca3af' }}>null</span>;
  if (typeof data === 'boolean') return <span style={{ color: '#f59e0b' }}>{String(data)}</span>;
  if (typeof data === 'number') return <span style={{ color: '#34d399' }}>{data}</span>;
  if (typeof data === 'string') return <span style={{ color: '#fca5a5' }}>"{data}"</span>;

  if (Array.isArray(data)) {
    if (data.length === 0) return <span style={{ color: '#6b7280' }}>[]</span>;
    return (
      <span>
        <button onClick={() => setCollapsed(!collapsed)} style={{ background: 'none', border: 'none', color: '#818cf8', cursor: 'pointer', padding: '0 4px', fontSize: '0.72rem', fontFamily: 'monospace' }}>
          {collapsed ? '▶' : '▼'}
        </button>
        {collapsed ? (
          <span style={{ color: '#6b7280' }}>[{data.length} items]</span>
        ) : (
          <>
            {'['}
            <div style={{ marginLeft: 20 }}>
              {data.map((item, i) => (
                <div key={i}>
                  <JsonNode data={item} depth={depth + 1} />
                  {i < data.length - 1 && <span style={{ color: '#4b5563' }}>,</span>}
                </div>
              ))}
            </div>
            {']'}
          </>
        )}
      </span>
    );
  }

  if (typeof data === 'object') {
    const keys = Object.keys(data);
    if (keys.length === 0) return <span style={{ color: '#6b7280' }}>{'{}'}</span>;
    return (
      <span>
        <button onClick={() => setCollapsed(!collapsed)} style={{ background: 'none', border: 'none', color: '#818cf8', cursor: 'pointer', padding: '0 4px', fontSize: '0.72rem', fontFamily: 'monospace' }}>
          {collapsed ? '▶' : '▼'}
        </button>
        {collapsed ? (
          <span style={{ color: '#6b7280' }}>{'{'}…{keys.length} keys{'}'}</span>
        ) : (
          <>
            {'{'}
            <div style={{ marginLeft: 20 }}>
              {keys.map((k, i) => (
                <div key={k}>
                  <span style={{ color: '#93c5fd' }}>"{k}"</span>
                  <span style={{ color: '#4b5563' }}>: </span>
                  <JsonNode data={data[k]} depth={depth + 1} />
                  {i < keys.length - 1 && <span style={{ color: '#4b5563' }}>,</span>}
                </div>
              ))}
            </div>
            {'}'}
          </>
        )}
      </span>
    );
  }

  return <span>{String(data)}</span>;
}

export default function Database() {
  const { data: db, isLoading, dataUpdatedAt } = useQuery({ queryKey: ['db-snapshot'], queryFn: getDbSnapshot, refetchInterval: 5000 });
  const [search, setSearch] = useState('');

  const bytes = db ? JSON.stringify(db).length : 0;
  const updatedAt = dataUpdatedAt ? new Date(dataUpdatedAt).toLocaleTimeString() : '';

  const filteredKeys = db
    ? (search ? Object.fromEntries(Object.entries(db).filter(([k]) => k.toLowerCase().includes(search.toLowerCase()))) : db)
    : null;

  return (
    <Box>
      <Box sx={{ mb: 3 }}>
        <Typography variant="h5" fontWeight={700}>Database Inspector</Typography>
        <Typography color="text.secondary" fontSize="0.85rem" sx={{ mb: 1 }}>
          Read-only view of the live database.json. Auto-refreshes every 5 seconds. Click ▶ to expand/collapse nodes.
        </Typography>
        <Box sx={{ display: 'flex', gap: 1 }}>
          <Chip label={`${bytes.toLocaleString()} bytes`} size="small" sx={{ bgcolor: '#1f2937' }} />
          <Chip label={`Last updated: ${updatedAt}`} size="small" sx={{ bgcolor: '#1f2937' }} />
          <Chip label="READ-ONLY" size="small" sx={{ bgcolor: 'rgba(239,68,68,0.1)', color: '#f87171', border: '1px solid rgba(239,68,68,0.3)' }} />
        </Box>
      </Box>

      <TextField
        label="Filter top-level keys..."
        value={search}
        onChange={e => setSearch(e.target.value)}
        fullWidth
        sx={{ mb: 2 }}
        size="small"
      />

      {isLoading && (
        <Box sx={{ display: 'flex', justifyContent: 'center', py: 8 }}>
          <CircularProgress sx={{ color: '#6366f1' }} />
        </Box>
      )}

      {filteredKeys && (
        <Paper sx={{ p: 2.5 }}>
          <Box
            sx={{
              fontFamily: "'JetBrains Mono', 'Fira Code', 'Courier New', monospace",
              fontSize: '0.8rem',
              lineHeight: 1.7,
              color: '#e5e7eb',
            }}
          >
            {'{'}
            {Object.entries(filteredKeys).map(([key, val], i, arr) => (
              <div key={key} style={{ marginLeft: 20 }}>
                <span style={{ color: '#93c5fd' }}>"{key}"</span>
                <span style={{ color: '#4b5563' }}>: </span>
                <JsonNode data={val} depth={1} />
                {i < arr.length - 1 && <span style={{ color: '#4b5563' }}>,</span>}
              </div>
            ))}
            {'}'}
          </Box>
        </Paper>
      )}
    </Box>
  );
}
