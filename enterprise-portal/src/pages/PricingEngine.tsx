// @ts-nocheck
import React, { useState, useEffect } from 'react';
import {
  Box, Typography, Card, CardContent, Grid, Button, Dialog, DialogTitle,
  DialogContent, DialogActions, TextField, IconButton, CircularProgress,
  Alert, Chip, Select, MenuItem, FormControl, InputLabel
} from '@mui/material';
import { Add as AddIcon, Delete as DeleteIcon, Refresh as RefreshIcon, Edit as EditIcon } from '@mui/icons-material';
import client from '../api/client';

interface PricingRule {
  id: string;
  ruleKey: string;
  serviceKey: string | null;
  branchId: string | null;
  value: number;
  valueType: 'FLAT' | 'PERCENT' | 'FORMULA';
  priority: number;
  description: string;
}

const RULE_KEYS = [
  'base_delivery_fee', 'delivery_fee_per_km', 'platform_fee', 'tax_rate',
  'surge_multiplier_max', 'commission_rate', 'min_order_value'
];

export default function PricingEngine() {
  const [rules, setRules] = useState<PricingRule[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [dialogOpen, setDialogOpen] = useState(false);
  const [editing, setEditing] = useState<Partial<PricingRule>>({});
  const [saving, setSaving] = useState(false);

  const load = async () => {
    setLoading(true);
    try {
      const res = await client.get('/api/v1/config/pricing');
      setRules(res.data?.data?.rules || []);
      setError(null);
    } catch (e: any) { setError('Failed to load pricing rules'); }
    finally { setLoading(false); }
  };

  useEffect(() => { load(); }, []);

  const handleSave = async () => {
    setSaving(true);
    try {
      await client.post('/api/v1/config/pricing', editing);
      setDialogOpen(false);
      setEditing({});
      await load();
    } catch (e) { console.error('Save failed:', e); }
    finally { setSaving(false); }
  };

  const grouped = rules.reduce((acc, rule) => {
    if (!acc[rule.ruleKey]) acc[rule.ruleKey] = [];
    acc[rule.ruleKey].push(rule);
    return acc;
  }, {} as Record<string, PricingRule[]>);

  return (
    <Box>
      <Box display="flex" justifyContent="space-between" alignItems="center" mb={3}>
        <Box>
          <Typography variant="h4" fontWeight="bold" color="primary">Pricing Engine</Typography>
          <Typography color="text.secondary" mt={0.5}>
            Configure all fees, taxes, and commissions. No code changes required.
          </Typography>
        </Box>
        <Box display="flex" gap={1}>
          <IconButton onClick={load} disabled={loading}><RefreshIcon /></IconButton>
          <Button variant="contained" startIcon={<AddIcon />}
            onClick={() => { setEditing({ valueType: 'FLAT', priority: 10 }); setDialogOpen(true); }}
            sx={{ background: 'linear-gradient(135deg, #bb86fc, #7c4dff)' }}>
            Add Rule
          </Button>
        </Box>
      </Box>

      {error && <Alert severity="error" sx={{ mb: 2 }}>{error}</Alert>}

      {loading ? <Box display="flex" justifyContent="center" mt={6}><CircularProgress /></Box> : (
        Object.entries(grouped).map(([ruleKey, groupRules]) => (
          <Box key={ruleKey} mb={3}>
            <Typography variant="overline" color="primary" fontWeight="bold" sx={{ letterSpacing: 2 }}>
              {ruleKey.replace(/_/g, ' ').toUpperCase()}
            </Typography>
            <Grid container spacing={2} mt={0.5}>
              {groupRules.map(rule => (
                <Grid item xs={12} sm={6} md={4} key={rule.id}>
                  <Card sx={{ background: 'linear-gradient(145deg, #1a1a2e, #16213e)', borderRadius: 3, border: '1px solid #2c2c2c' }}>
                    <CardContent>
                      <Box display="flex" justifyContent="space-between">
                        <Box>
                          <Typography variant="h5" fontWeight="bold" color="primary">
                            {rule.valueType === 'PERCENT' ? `${rule.value}%` : `${rule.value}`}
                          </Typography>
                          <Chip label={rule.valueType} size="small" sx={{ mr: 0.5 }} />
                          {rule.serviceKey && <Chip label={rule.serviceKey} size="small" color="info" sx={{ mr: 0.5 }} />}
                          {rule.branchId && <Chip label={`Branch: ${rule.branchId.substring(0, 8)}…`} size="small" color="warning" />}
                          <Typography variant="caption" color="text.secondary" display="block" mt={0.5}>
                            {rule.description || '—'}
                          </Typography>
                          <Typography variant="caption" color="text.secondary">Priority: {rule.priority}</Typography>
                        </Box>
                        <IconButton size="small" onClick={() => { setEditing(rule); setDialogOpen(true); }}>
                          <EditIcon fontSize="small" />
                        </IconButton>
                      </Box>
                    </CardContent>
                  </Card>
                </Grid>
              ))}
            </Grid>
          </Box>
        ))
      )}

      <Dialog open={dialogOpen} onClose={() => setDialogOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle>{editing.id ? 'Edit Pricing Rule' : 'Add Pricing Rule'}</DialogTitle>
        <DialogContent>
          <Box display="flex" flexDirection="column" gap={2} mt={1}>
            <FormControl fullWidth>
              <InputLabel>Rule Key</InputLabel>
              <Select value={editing.ruleKey || ''} label="Rule Key"
                onChange={e => setEditing(p => ({ ...p, ruleKey: e.target.value }))}>
                {RULE_KEYS.map(k => <MenuItem key={k} value={k}>{k.replace(/_/g, ' ')}</MenuItem>)}
              </Select>
            </FormControl>
            <TextField label="Service Key (optional)" value={editing.serviceKey || ''}
              onChange={e => setEditing(p => ({ ...p, serviceKey: e.target.value || null }))} />
            <TextField label="Value" type="number" value={editing.value ?? ''}
              onChange={e => setEditing(p => ({ ...p, value: parseFloat(e.target.value) }))} />
            <FormControl fullWidth>
              <InputLabel>Value Type</InputLabel>
              <Select value={editing.valueType || 'FLAT'} label="Value Type"
                onChange={e => setEditing(p => ({ ...p, valueType: e.target.value as any }))}>
                <MenuItem value="FLAT">FLAT (absolute amount)</MenuItem>
                <MenuItem value="PERCENT">PERCENT (%)</MenuItem>
                <MenuItem value="FORMULA">FORMULA (custom expression)</MenuItem>
              </Select>
            </FormControl>
            <TextField label="Priority (higher = applied first)" type="number" value={editing.priority ?? 10}
              onChange={e => setEditing(p => ({ ...p, priority: parseInt(e.target.value) }))} />
            <TextField label="Description" multiline rows={2} value={editing.description || ''}
              onChange={e => setEditing(p => ({ ...p, description: e.target.value }))} />
          </Box>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setDialogOpen(false)}>Cancel</Button>
          <Button variant="contained" onClick={handleSave} disabled={saving}>
            {saving ? <CircularProgress size={20} /> : 'Save'}
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
}
