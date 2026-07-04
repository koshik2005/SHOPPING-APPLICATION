// @ts-nocheck
import React, { useState, useEffect } from 'react';
import {
  Box, Typography, Grid, Card, CardContent, Chip, Switch, FormControlLabel,
  IconButton, Alert, CircularProgress, Divider, Tooltip, TextField, InputAdornment
} from '@mui/material';
import { Refresh as RefreshIcon, Search as SearchIcon } from '@mui/icons-material';
import client from '../api/client';

interface FeatureFlag {
  id: string;
  flagKey: string;
  enabled: boolean;
  scope: string;
  scopeId: string | null;
  description: string;
}

export default function FeatureFlags() {
  const [flags, setFlags] = useState<FeatureFlag[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [search, setSearch] = useState('');

  const load = async () => {
    setLoading(true);
    try {
      const res = await client.get('/api/v1/config/features');
      setFlags(res.data?.data?.flags || []);
      setError(null);
    } catch (e: any) {
      setError('Failed to load feature flags');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { load(); }, []);

  const handleToggle = async (flag: FeatureFlag) => {
    const originalFlags = [...flags];
    // Optimistic update
    setFlags(prev => prev.map(f => f.id === flag.id ? { ...f, enabled: !f.enabled } : f));
    try {
      await client.post('/api/v1/config/features/toggle', {
        flagKey: flag.flagKey,
        scope: flag.scope,
        scopeId: flag.scopeId,
        enabled: !flag.enabled,
      });
    } catch (e) {
      // Revert on error
      setFlags(originalFlags);
      console.error('Toggle failed:', e);
    }
  };

  const filtered = flags.filter(f =>
    f.flagKey.toLowerCase().includes(search.toLowerCase()) ||
    (f.description && f.description.toLowerCase().includes(search.toLowerCase()))
  );

  const groupedByPrefix = filtered.reduce((acc, flag) => {
    const prefix = flag.flagKey.split('.')[0];
    if (!acc[prefix]) acc[prefix] = [];
    acc[prefix].push(flag);
    return acc;
  }, {} as Record<string, FeatureFlag[]>);

  return (
    <Box>
      <Box display="flex" justifyContent="space-between" alignItems="center" mb={3}>
        <Box>
          <Typography variant="h4" fontWeight="bold" color="primary">Feature Flags</Typography>
          <Typography color="text.secondary" mt={0.5}>
            Toggle platform features at runtime without code deployment.
          </Typography>
        </Box>
        <Box display="flex" gap={1} alignItems="center">
          <TextField
            size="small"
            placeholder="Search flags..."
            value={search}
            onChange={e => setSearch(e.target.value)}
            InputProps={{ startAdornment: <InputAdornment position="start"><SearchIcon fontSize="small" /></InputAdornment> }}
          />
          <IconButton onClick={load} disabled={loading}><RefreshIcon /></IconButton>
        </Box>
      </Box>

      {error && <Alert severity="error" sx={{ mb: 2 }}>{error}</Alert>}

      {loading ? (
        <Box display="flex" justifyContent="center" mt={6}><CircularProgress /></Box>
      ) : (
        Object.entries(groupedByPrefix).map(([prefix, groupFlags]) => (
          <Box key={prefix} mb={3}>
            <Typography variant="overline" color="primary" fontWeight="bold" sx={{ letterSpacing: 2 }}>
              {prefix.toUpperCase()}
            </Typography>
            <Divider sx={{ mb: 2, borderColor: '#2c2c2c' }} />
            <Grid container spacing={2}>
              {groupFlags.map(flag => (
                <Grid item xs={12} sm={6} md={4} key={flag.id}>
                  <Card sx={{
                    background: flag.enabled
                      ? 'linear-gradient(145deg, #0a2a0a, #1a3a1a)'
                      : 'linear-gradient(145deg, #1a1a2e, #16213e)',
                    border: `1px solid ${flag.enabled ? '#4CAF5055' : '#333'}`,
                    borderRadius: 3,
                    transition: 'all 0.3s ease',
                  }}>
                    <CardContent>
                      <Box display="flex" justifyContent="space-between" alignItems="flex-start">
                        <Box flex={1}>
                          <Typography
                            variant="body2"
                            fontFamily="monospace"
                            color={flag.enabled ? '#4CAF50' : 'text.secondary'}
                            fontWeight="bold"
                            sx={{ wordBreak: 'break-all' }}
                          >
                            {flag.flagKey}
                          </Typography>
                          {flag.description && (
                            <Typography variant="caption" color="text.secondary" display="block" mt={0.5}>
                              {flag.description}
                            </Typography>
                          )}
                          <Chip
                            label={flag.scope}
                            size="small"
                            sx={{ mt: 1, fontSize: '0.6rem', height: 18 }}
                            variant="outlined"
                          />
                        </Box>
                        <Tooltip title={flag.enabled ? 'Disable feature' : 'Enable feature'}>
                          <Switch
                            checked={flag.enabled}
                            onChange={() => handleToggle(flag)}
                            size="small"
                            color="success"
                          />
                        </Tooltip>
                      </Box>
                    </CardContent>
                  </Card>
                </Grid>
              ))}
            </Grid>
          </Box>
        ))
      )}
    </Box>
  );
}
