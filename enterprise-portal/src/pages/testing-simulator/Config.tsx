// @ts-nocheck
import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import {
  Box, Typography, Card, CardContent, Grid, Switch, FormControlLabel,
  TextField, Button, Snackbar, Stack, Chip, Alert, Divider, MenuItem,
} from '@mui/material';
import { Settings, Save } from '@mui/icons-material';
import { getConfig, updateConfig } from '../../api/portal';

export default function Config() {
  const qc = useQueryClient();
  const { data: config = {} } = useQuery({ queryKey: ['config'], queryFn: getConfig, refetchInterval: 5000 });
  const [snack, setSnack] = useState('');
  const [drafts, setDrafts] = useState<Record<string, any>>({});

  const updateM = useMutation({
    mutationFn: (d: any) => updateConfig(d),
    onSuccess: () => { qc.invalidateQueries({ queryKey: ['config'] }); setDrafts({}); setSnack('Config updated!'); }
  });

  const setDraft = (key: string, value: any) => setDrafts(d => ({ ...d, [key]: value }));
  const getValue = (key: string) => key in drafts ? drafts[key] : (config as any)[key];

  const boolFields = ['maintenanceMode', 'forceUpdateRequired'];
  const strFields = ['appVersion', 'apiVersion', 'termsUrl', 'privacyUrl', 'passwordPolicyRegex'];
  const numFields = [
    { key: 'otpLength', label: 'OTP Length' },
    { key: 'otpExpirySeconds', label: 'OTP Expiry (s)' },
    { key: 'sessionTimeoutSeconds', label: 'Session Timeout (s)' },
    { key: 'maxLoginAttempts', label: 'Max Login Attempts' },
    { key: 'baseDeliveryFee', label: 'Base Delivery Fee ($)' },
    { key: 'deliveryFeePerMile', label: 'Fee per Mile ($)' },
    { key: 'platformFee', label: 'Platform Fee ($)' },
    { key: 'taxRate', label: 'Tax Rate' },
  ];

  const hasDrafts = Object.keys(drafts).length > 0;

  return (
    <Box>
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', mb: 3 }}>
        <Box>
          <Typography variant="h5" fontWeight={700}>App Config Simulator</Typography>
          <Typography color="text.secondary" fontSize="0.85rem">
            Edit global configuration values. Changes take effect in the customer app immediately.
          </Typography>
        </Box>
        {hasDrafts && (
          <Button variant="contained" startIcon={<Save />} onClick={() => updateM.mutate(drafts)} disabled={updateM.isPending}>
            Save {Object.keys(drafts).length} Changes
          </Button>
        )}
      </Box>

      {(config as any).maintenanceMode && (
        <Alert severity="error" sx={{ mb: 2 }}>
          ⚠️ MAINTENANCE MODE IS ACTIVE — The customer app will show a maintenance screen!
        </Alert>
      )}

      <Grid container spacing={2}>
        {/* Boolean toggles */}
        <Grid item xs={12} md={6}>
          <Card>
            <CardContent>
              <Typography fontWeight={700} sx={{ mb: 2 }}>Feature Flags</Typography>
              <Stack spacing={1.5}>
                {boolFields.map(key => (
                  <Box key={key} sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', p: 1.5, bgcolor: '#0d1525', borderRadius: 2 }}>
                    <Box>
                      <Typography fontWeight={600} fontSize="0.85rem" sx={{ textTransform: 'capitalize' }}>
                        {key.replace(/([A-Z])/g, ' $1').trim()}
                      </Typography>
                      {key === 'maintenanceMode' && (
                        <Typography fontSize="0.72rem" color="text.secondary">⚠️ Forces maintenance screen in app</Typography>
                      )}
                      {key === 'forceUpdateRequired' && (
                        <Typography fontSize="0.72rem" color="text.secondary">Forces app update dialog</Typography>
                      )}
                    </Box>
                    <Switch
                      checked={!!getValue(key)}
                      onChange={e => setDraft(key, e.target.checked)}
                      color={key === 'maintenanceMode' ? 'error' : 'warning'}
                    />
                  </Box>
                ))}

                <Box sx={{ p: 1.5, bgcolor: '#0d1525', borderRadius: 2 }}>
                  <Typography fontWeight={600} fontSize="0.85rem" sx={{ mb: 1 }}>Enabled Login Methods</Typography>
                  {['phone', 'google', 'apple'].map(method => {
                    const enabledMethods = getValue('enabledLoginMethods') ?? ['phone', 'google', 'apple'];
                    const isEnabled = enabledMethods.includes(method);
                    return (
                      <FormControlLabel
                        key={method}
                        control={
                          <Switch
                            size="small"
                            checked={isEnabled}
                            onChange={e => {
                              const current = [...(getValue('enabledLoginMethods') ?? ['phone', 'google', 'apple'])];
                              const updated = e.target.checked ? [...current, method] : current.filter(m => m !== method);
                              setDraft('enabledLoginMethods', updated);
                            }}
                          />
                        }
                        label={<Chip label={method} size="small" sx={{ textTransform: 'capitalize' }} />}
                        sx={{ display: 'flex', width: '100%' }}
                      />
                    );
                  })}
                </Box>
              </Stack>
            </CardContent>
          </Card>
        </Grid>

        {/* Numeric fields */}
        <Grid item xs={12} md={6}>
          <Card>
            <CardContent>
              <Typography fontWeight={700} sx={{ mb: 2 }}>Numeric Settings</Typography>
              <Grid container spacing={1.5}>
                {numFields.map(({ key, label }) => (
                  <Grid item xs={6} key={key}>
                    <TextField
                      label={label}
                      type="number"
                      value={getValue(key) ?? ''}
                      onChange={e => setDraft(key, parseFloat(e.target.value))}
                      fullWidth size="small"
                    />
                  </Grid>
                ))}
              </Grid>
            </CardContent>
          </Card>
        </Grid>

        {/* String fields */}
        <Grid item xs={12}>
          <Card>
            <CardContent>
              <Typography fontWeight={700} sx={{ mb: 2 }}>String Settings</Typography>
              <Grid container spacing={2}>
                {strFields.map(key => (
                  <Grid item xs={12} md={6} key={key}>
                    <TextField
                      label={key.replace(/([A-Z])/g, ' $1').trim()}
                      value={getValue(key) ?? ''}
                      onChange={e => setDraft(key, e.target.value)}
                      fullWidth size="small"
                    />
                  </Grid>
                ))}
              </Grid>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {hasDrafts && (
        <Box sx={{ mt: 2, p: 2, bgcolor: 'rgba(99,102,241,0.08)', borderRadius: 2, border: '1px solid rgba(99,102,241,0.25)' }}>
          <Typography fontSize="0.82rem" color="primary.light" fontWeight={600}>
            ✏️ {Object.keys(drafts).length} unsaved changes: {Object.keys(drafts).join(', ')}
          </Typography>
        </Box>
      )}

      <Snackbar open={!!snack} autoHideDuration={3000} onClose={() => setSnack('')} message={snack} anchorOrigin={{ vertical: 'bottom', horizontal: 'right' }} />
    </Box>
  );
}
