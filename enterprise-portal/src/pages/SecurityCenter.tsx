// @ts-nocheck
import React, { useState } from 'react';
import {
  Box, Card, CardContent, Typography, Grid, Button, Table, TableBody,
  TableCell, TableContainer, TableHead, TableRow, Chip, IconButton, Alert
} from '@mui/material';
import {
  Shield, Lock, LockOpen, DeviceUnknown, HighlightOff, CheckCircle
} from '@mui/icons-material';

interface LockedAccount {
  userId: string;
  email: string;
  lockType: 'TEMPORARY' | 'PERMANENT';
  lockedAt: string;
  reason: string;
}

export default function SecurityCenter() {
  const [lockedAccounts, setLockedAccounts] = useState<LockedAccount[]>([
    { userId: 'u1', email: 'merchant_owner@hyperlocal.app', lockType: 'TEMPORARY', lockedAt: '2026-07-03 11:15 AM', reason: '5 failed logins exceeded' },
    { userId: 'u2', email: 'support_agent_2@hyperlocal.app', lockType: 'PERMANENT', lockedAt: '2026-07-03 09:00 AM', reason: '10 failed logins exceeded' }
  ]);

  const [blockedDevices, setBlockedDevices] = useState([
    { deviceId: 'dev_83b2072f', user: 'delivery_rider_101@hyperlocal.app', blockedAt: '2026-07-03 10:45 AM', reason: 'Emulator mock GPS detected' }
  ]);

  const handleUnlock = (email: string) => {
    setLockedAccounts(lockedAccounts.filter(acc => acc.email !== email));
  };

  return (
    <Box>
      <Box display="flex" justifyContent="space-between" alignItems="center" mb={4}>
        <Typography variant="h4" fontWeight="bold">
          Enterprise Security Dashboard
        </Typography>
        <Chip icon={<Shield color="success" />} label="Zero Trust Active" variant="outlined" color="success" />
      </Box>

      <Grid container spacing={3} mb={4}>
        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Typography variant="body2" color="text.secondary" gutterBottom>
                Active Sessions count
              </Typography>
              <Typography variant="h5" fontWeight="bold">
                12
              </Typography>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Typography variant="body2" color="text.secondary" gutterBottom>
                Locked User Accounts
              </Typography>
              <Typography variant="h5" fontWeight="bold" color="error">
                {lockedAccounts.length}
              </Typography>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Typography variant="body2" color="text.secondary" gutterBottom>
                Blacklisted Hardware Fingerprints
              </Typography>
              <Typography variant="h5" fontWeight="bold" color="warning.main">
                {blockedDevices.length}
              </Typography>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Typography variant="body2" color="text.secondary" gutterBottom>
                Failed Logins Today
              </Typography>
              <Typography variant="h5" fontWeight="bold">
                32 attempts
              </Typography>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      <Grid container spacing={3}>
        <Grid item xs={12} md={7}>
          <Card sx={{ mb: 3 }}>
            <CardContent>
              <Typography variant="h6" fontWeight="bold" gutterBottom>
                Locked User Accounts Queue
              </Typography>
              <TableContainer>
                <Table>
                  <TableHead>
                    <TableRow>
                      <TableCell>Account Email</TableCell>
                      <TableCell>Lock Type</TableCell>
                      <TableCell>Locked Time</TableCell>
                      <TableCell>Reason</TableCell>
                      <TableCell align="right">Unlock</TableCell>
                    </TableRow>
                  </TableHead>
                  <TableBody>
                    {lockedAccounts.map((acc) => (
                      <TableRow key={acc.email}>
                        <TableCell fontWeight="bold">{acc.email}</TableCell>
                        <TableCell>
                          <Chip
                            label={acc.lockType}
                            size="small"
                            color={acc.lockType === 'PERMANENT' ? 'error' : 'warning'}
                          />
                        </TableCell>
                        <TableCell>{acc.lockedAt}</TableCell>
                        <TableCell>{acc.reason}</TableCell>
                        <TableCell align="right">
                          <Button
                            size="small"
                            variant="outlined"
                            startIcon={<LockOpen />}
                            onClick={() => handleUnlock(acc.email)}
                          >
                            Unlock
                          </Button>
                        </TableCell>
                      </TableRow>
                    ))}
                    {lockedAccounts.length === 0 && (
                      <TableRow>
                        <TableCell colSpan={5} align="center">
                          <Alert severity="success" icon={false} sx={{ justifyContent: 'center' }}>
                            No locked accounts present.
                          </Alert>
                        </TableCell>
                      </TableRow>
                    )}
                  </TableBody>
                </Table>
              </TableContainer>
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} md={5}>
          <Card>
            <CardContent>
              <Typography variant="h6" fontWeight="bold" gutterBottom>
                Blacklisted Devices Registry
              </Typography>
              <TableContainer>
                <Table>
                  <TableHead>
                    <TableRow>
                      <TableCell>Fingerprint</TableCell>
                      <TableCell>User</TableCell>
                      <TableCell align="right">Clear</TableCell>
                    </TableRow>
                  </TableHead>
                  <TableBody>
                    {blockedDevices.map((dev) => (
                      <TableRow key={dev.deviceId}>
                        <TableCell fontWeight="bold">{dev.deviceId}</TableCell>
                        <TableCell>{dev.user}</TableCell>
                        <TableCell align="right">
                          <IconButton color="success" size="small" onClick={() => setBlockedDevices([])}>
                            <CheckCircle />
                          </IconButton>
                        </TableCell>
                      </TableRow>
                    ))}
                    {blockedDevices.length === 0 && (
                      <TableRow>
                        <TableCell colSpan={3} align="center">
                          <Typography variant="caption" color="text.secondary">
                            No blacklisted devices.
                          </Typography>
                        </TableCell>
                      </TableRow>
                    )}
                  </TableBody>
                </Table>
              </TableContainer>
            </CardContent>
          </Card>
        </Grid>
      </Grid>
    </Box>
  );
}
