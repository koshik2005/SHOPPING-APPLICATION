// @ts-nocheck
import React, { useState, useEffect } from 'react';
import {
  Box, Typography, TextField, Table, TableHead, TableBody, TableRow, TableCell,
  IconButton, Button, Dialog, DialogTitle, DialogContent, DialogActions,
  CircularProgress, Alert, InputAdornment, Select, MenuItem, FormControl, InputLabel
} from '@mui/material';
import { Add as AddIcon, Edit as EditIcon, Refresh as RefreshIcon, Search as SearchIcon } from '@mui/icons-material';
import client from '../api/client';

interface LocalisationString {
  id: string;
  stringKey: string;
  locale: string;
  value: string;
  description: string;
}

export default function LocalisationManager() {
  const [strings, setStrings] = useState<LocalisationString[]>([]);
  const [locale, setLocale] = useState('en');
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [search, setSearch] = useState('');
  const [dialogOpen, setDialogOpen] = useState(false);
  const [editing, setEditing] = useState<Partial<LocalisationString>>({});
  const [saving, setSaving] = useState(false);

  const load = async () => {
    setLoading(true);
    try {
      const res = await client.get('/api/v1/config/i18n', { params: { locale } });
      const rawStrings: Record<string, string> = res.data?.data?.strings || {};
      const parsed: LocalisationString[] = Object.entries(rawStrings).map(([key, val], idx) => ({
        id: `str-${idx}`,
        stringKey: key,
        locale,
        value: val,
        description: ''
      }));
      setStrings(parsed);
      setError(null);
    } catch (e: any) {
      setError('Failed to load localisation strings');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { load(); }, [locale]);

  const handleSave = async () => {
    setSaving(true);
    try {
      await client.post('/api/v1/config/i18n', {
        key: editing.stringKey,
        locale,
        value: editing.value
      });
      setDialogOpen(false);
      setEditing({});
      await load();
    } catch (e) {
      console.error('Save failed:', e);
    } finally {
      setSaving(false);
    }
  };

  const filtered = strings.filter(s =>
    s.stringKey.toLowerCase().includes(search.toLowerCase()) ||
    s.value.toLowerCase().includes(search.toLowerCase())
  );

  return (
    <Box>
      <Box display="flex" justifyContent="space-between" alignItems="center" mb={3}>
        <Box>
          <Typography variant="h4" fontWeight="bold" color="primary">Localisation Manager</Typography>
          <Typography color="text.secondary" mt={0.5}>
            Manage translated text and UI string literals dynamically. Supports multiple locales.
          </Typography>
        </Box>
        <Box display="flex" gap={2} alignItems="center">
          <FormControl size="small" sx={{ minWidth: 120 }}>
            <InputLabel>Locale</InputLabel>
            <Select value={locale} label="Locale" onChange={e => setLocale(e.target.value)}>
              <MenuItem value="en">English (en)</MenuItem>
              <MenuItem value="hi">Hindi (hi)</MenuItem>
              <MenuItem value="ta">Tamil (ta)</MenuItem>
              <MenuItem value="te">Telugu (te)</MenuItem>
            </Select>
          </FormControl>
          <TextField
            size="small"
            placeholder="Search strings..."
            value={search}
            onChange={e => setSearch(e.target.value)}
            InputProps={{ startAdornment: <InputAdornment position="start"><SearchIcon fontSize="small" /></InputAdornment> }}
          />
          <IconButton onClick={load} disabled={loading}><RefreshIcon /></IconButton>
          <Button variant="contained" startIcon={<AddIcon />}
            onClick={() => { setEditing({ stringKey: '', value: '' }); setDialogOpen(true); }}
            sx={{ background: 'linear-gradient(135deg, #bb86fc, #7c4dff)' }}>
            Add String
          </Button>
        </Box>
      </Box>

      {error && <Alert severity="error" sx={{ mb: 2 }}>{error}</Alert>}

      {loading ? (
        <Box display="flex" justifyContent="center" mt={6}><CircularProgress /></Box>
      ) : (
        <Table sx={{ background: '#1a1a2e', borderRadius: 3, overflow: 'hidden' }}>
          <TableHead sx={{ backgroundColor: '#16213e' }}>
            <TableRow>
              <TableCell sx={{ color: '#bb86fc', fontWeight: 'bold' }}>String Key</TableCell>
              <TableCell sx={{ color: '#bb86fc', fontWeight: 'bold' }}>Value ({locale})</TableCell>
              <TableCell align="right" sx={{ color: '#bb86fc', fontWeight: 'bold' }}>Actions</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {filtered.map(str => (
              <TableRow key={str.stringKey} sx={{ '&:hover': { backgroundColor: '#bb86fc0a' } }}>
                <TableCell sx={{ fontFamily: 'monospace', color: '#ccc' }}>{str.stringKey}</TableCell>
                <TableCell sx={{ color: 'white' }}>{str.value}</TableCell>
                <TableCell align="right">
                  <IconButton size="small" onClick={() => { setEditing(str); setDialogOpen(true); }}>
                    <EditIcon fontSize="small" />
                  </IconButton>
                </TableCell>
              </TableRow>
            ))}
            {filtered.length === 0 && (
              <TableRow>
                <TableCell colSpan={3} align="center" sx={{ color: '#666' }}>No strings found</TableCell>
              </TableRow>
            )}
          </TableBody>
        </Table>
      )}

      <Dialog open={dialogOpen} onClose={() => setDialogOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle>{editing.id ? 'Edit Translation' : 'Add New String'}</DialogTitle>
        <DialogContent>
          <Box display="flex" flexDirection="column" gap={2} mt={1}>
            <TextField
              label="String Key"
              value={editing.stringKey || ''}
              disabled={!!editing.id}
              onChange={e => setEditing(p => ({ ...p, stringKey: e.target.value }))}
              helperText="E.g. home.search.placeholder"
            />
            <TextField
              label={`Value (${locale})`}
              value={editing.value || ''}
              multiline
              rows={3}
              onChange={e => setEditing(p => ({ ...p, value: e.target.value }))}
            />
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
