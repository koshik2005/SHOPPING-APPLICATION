// @ts-nocheck
import React, { useState } from 'react';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import {
  Box, Typography, Grid, Card, CardContent, Switch, FormControlLabel,
  Chip, Snackbar, Alert, Divider, Stack,
} from '@mui/material';
import { WifiOff, GpsOff, Notifications, Camera, Bluetooth, LocationOff, CloudOff } from '@mui/icons-material';
import { getDbSnapshot, setPermissions } from '../../api/portal';

const FLAGS = [
  { key: 'gpsDisabled',       label: 'GPS Disabled',          icon: <GpsOff />,          color: '#ef4444', desc: 'Simulates device GPS turned off' },
  { key: 'internetOff',       label: 'Internet Offline',      icon: <WifiOff />,          color: '#ef4444', desc: 'Simulates no internet connection' },
  { key: 'notificationsOff',  label: 'Notifications Off',     icon: <Notifications />,   color: '#f59e0b', desc: 'Simulates notifications permission denied' },
  { key: 'cameraOff',         label: 'Camera Off',            icon: <Camera />,           color: '#f59e0b', desc: 'Simulates camera permission denied' },
  { key: 'locationPermDenied',label: 'Location Perm Denied',  icon: <LocationOff />,      color: '#f59e0b', desc: 'Simulates location permission denied' },
  { key: 'bluetoothOff',      label: 'Bluetooth Disabled',    icon: <Bluetooth />,        color: '#9ca3af', desc: 'Simulates Bluetooth turned off' },
  { key: 'offlineMode',       label: 'Full Offline Mode',     icon: <CloudOff />,         color: '#ef4444', desc: 'Simulates complete device offline' },
];

export default function Permissions() {
  const qc = useQueryClient();
  const { data: db } = useQuery({ queryKey: ['db-snapshot'], queryFn: getDbSnapshot, refetchInterval: 3000 });
  const [snack, setSnack] = useState('');

  const setM = useMutation({
    mutationFn: setPermissions,
    onSuccess: () => { qc.invalidateQueries({ queryKey: ['db-snapshot'] }); setSnack('Permission flag updated!'); }
  });

  const perms = db?.portal_permissions ?? {};
  const activeCount = Object.values(perms).filter(Boolean).length;

  return (
    <Box>
      <Box sx={{ mb: 3 }}>
        <Typography variant="h5" fontWeight={700}>Permission Simulator</Typography>
        <Typography color="text.secondary" fontSize="0.85rem" sx={{ mb: 1 }}>
          Toggle system permission flags to simulate edge cases. These flags are stored in database.json
          and can be read by the customer app to test graceful degradation.
        </Typography>
        <Box sx={{ display: 'flex', gap: 1 }}>
          <Chip label={`${activeCount} flags active`} size="small" color={activeCount > 0 ? 'warning' : 'success'} />
          <Chip label="Flags stored in database.json → portal_permissions" size="small" sx={{ bgcolor: '#1f2937', fontSize: '0.7rem' }} />
        </Box>
      </Box>

      {activeCount > 0 && (
        <Alert severity="warning" sx={{ mb: 2 }}>
          {activeCount} permission flag{activeCount > 1 ? 's are' : ' is'} active. The customer app may behave differently.
        </Alert>
      )}

      <Grid container spacing={2}>
        {FLAGS.map(f => {
          const isActive = !!perms[f.key];
          return (
            <Grid item xs={12} sm={6} md={4} key={f.key}>
              <Card
                sx={{
                  border: isActive ? `1px solid ${f.color}60` : '1px solid #1f2937',
                  bgcolor: isActive ? `${f.color}0d` : '#111827',
                  transition: 'all 0.2s',
                }}
              >
                <CardContent>
                  <Box sx={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between' }}>
                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5 }}>
                      <Box sx={{ color: isActive ? f.color : '#4b5563', display: 'flex', transition: 'color 0.2s' }}>
                        {f.icon}
                      </Box>
                      <Box>
                        <Typography fontWeight={600} fontSize="0.88rem">{f.label}</Typography>
                        <Typography fontSize="0.72rem" color="text.secondary">{f.desc}</Typography>
                      </Box>
                    </Box>
                    <Switch
                      checked={isActive}
                      onChange={e => setM.mutate({ [f.key]: e.target.checked })}
                      sx={{
                        '& .MuiSwitch-switchBase.Mui-checked': { color: f.color },
                        '& .MuiSwitch-switchBase.Mui-checked + .MuiSwitch-track': { bgcolor: f.color },
                      }}
                    />
                  </Box>
                  <Box sx={{ mt: 1.5 }}>
                    <Chip
                      label={isActive ? '🔴 ACTIVE — App affected' : '🟢 Normal — No effect'}
                      size="small"
                      sx={{ bgcolor: isActive ? `${f.color}20` : 'rgba(16,185,129,0.1)', color: isActive ? f.color : '#10b981', fontSize: '0.68rem' }}
                    />
                  </Box>
                </CardContent>
              </Card>
            </Grid>
          );
        })}
      </Grid>

      <Snackbar open={!!snack} autoHideDuration={3000} onClose={() => setSnack('')} message={snack} anchorOrigin={{ vertical: 'bottom', horizontal: 'right' }} />
    </Box>
  );
}
