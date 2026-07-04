// @ts-nocheck
import React, { useState, useEffect } from 'react';
import {
  Box, Typography, FormControl, InputLabel, Select, MenuItem, Grid, Card, CardContent,
  Chip, Button, IconButton, CircularProgress, Alert, Table, TableHead, TableBody,
  TableRow, TableCell, Divider, Stack
} from '@mui/material';
import { Refresh as RefreshIcon, AccountTree as WorkflowIcon } from '@mui/icons-material';
import client from '../api/client';

interface WorkflowStep {
  id: string;
  serviceKey: string;
  stepKey: string;
  displayLabel: string;
  initial: boolean;
  terminal: boolean;
  allowedNextSteps: string; // JSON string or array
  allowedRoles: string;     // JSON string or array
  displayOrder: number;
  colorHex: string;
}

export default function WorkflowDesigner() {
  const [serviceKey, setServiceKey] = useState('food');
  const [steps, setSteps] = useState<WorkflowStep[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const load = async () => {
    setLoading(true);
    try {
      const res = await client.get('/api/v1/config/workflow', { params: { serviceKey } });
      setSteps(res.data?.data?.steps || []);
      setError(null);
    } catch (e: any) {
      setError('Failed to load workflow steps');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { load(); }, [serviceKey]);

  const parseJsonArray = (val: any): string[] => {
    if (typeof val === 'string') {
      try {
        return JSON.parse(val);
      } catch {
        return [];
      }
    }
    return Array.isArray(val) ? val : [];
  };

  return (
    <Box>
      <Box display="flex" justifyContent="space-between" alignItems="center" mb={3}>
        <Box>
          <Typography variant="h4" fontWeight="bold" color="primary">Workflow Designer</Typography>
          <Typography color="text.secondary" mt={0.5}>
            Design state transition workflows and permission gating for order status updates dynamically.
          </Typography>
        </Box>
        <Box display="flex" gap={2} alignItems="center">
          <FormControl size="small" sx={{ minWidth: 150 }}>
            <InputLabel>Service Type</InputLabel>
            <Select value={serviceKey} label="Service Type" onChange={e => setServiceKey(e.target.value)}>
              <MenuItem value="food">Restaurants (food)</MenuItem>
              <MenuItem value="grocery">Grocery (grocery)</MenuItem>
              <MenuItem value="medicine">Pharmacy (medicine)</MenuItem>
              <MenuItem value="rides">Ride Booking (rides)</MenuItem>
              <MenuItem value="courier">Courier (courier)</MenuItem>
            </Select>
          </FormControl>
          <IconButton onClick={load} disabled={loading}><RefreshIcon /></IconButton>
        </Box>
      </Box>

      {error && <Alert severity="error" sx={{ mb: 2 }}>{error}</Alert>}

      {loading ? (
        <Box display="flex" justifyContent="center" mt={6}><CircularProgress /></Box>
      ) : (
        <Grid container spacing={3}>
          <Grid item xs={12} md={7}>
            <Card sx={{ background: '#1a1a2e', border: '1px solid #2c2c2c', borderRadius: 3 }}>
              <CardContent>
                <Typography variant="h6" fontWeight="bold" mb={2} color="primary" display="flex" alignItems="center" gap={1}>
                  <WorkflowIcon /> Ordered Steps
                </Typography>
                <Table size="small">
                  <TableHead>
                    <TableRow>
                      <TableCell sx={{ color: '#bb86fc', fontWeight: 'bold' }}>Order</TableCell>
                      <TableCell sx={{ color: '#bb86fc', fontWeight: 'bold' }}>Step Key</TableCell>
                      <TableCell sx={{ color: '#bb86fc', fontWeight: 'bold' }}>Display Label</TableCell>
                      <TableCell sx={{ color: '#bb86fc', fontWeight: 'bold' }}>Attributes</TableCell>
                    </TableRow>
                  </TableHead>
                  <TableBody>
                    {steps.map(step => (
                      <TableRow key={step.stepKey} sx={{ '&:hover': { backgroundColor: '#bb86fc05' } }}>
                        <TableCell sx={{ color: 'white' }}>{step.displayOrder}</TableCell>
                        <TableCell sx={{ fontFamily: 'monospace', color: '#ccc' }}>{step.stepKey}</TableCell>
                        <TableCell sx={{ color: 'white' }}>
                          <Chip label={step.displayLabel} size="small"
                            sx={{ backgroundColor: step.colorHex || '#bb86fc', color: '#000', fontWeight: 'bold' }} />
                        </TableCell>
                        <TableCell>
                          <Stack direction="row" spacing={0.5}>
                            {step.initial && <Chip label="Initial" size="small" color="primary" variant="outlined" sx={{ height: 18 }} />}
                            {step.terminal && <Chip label="Terminal" size="small" color="secondary" variant="outlined" sx={{ height: 18 }} />}
                          </Stack>
                        </TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              </CardContent>
            </Card>
          </Grid>

          <Grid item xs={12} md={5}>
            <Card sx={{ background: '#1a1a2e', border: '1px solid #2c2c2c', borderRadius: 3 }}>
              <CardContent>
                <Typography variant="h6" fontWeight="bold" mb={2} color="primary">Transitions & Permissions</Typography>
                {steps.map(step => {
                  const nextSteps = parseJsonArray(step.allowedNextSteps);
                  const allowedRoles = parseJsonArray(step.allowedRoles);
                  return (
                    <Box key={step.stepKey} mb={2}>
                      <Typography variant="subtitle2" fontWeight="bold" color="white">{step.displayLabel}</Typography>
                      <Box mt={0.5} display="flex" flexWrap="wrap" gap={0.5}>
                        <Typography variant="caption" color="text.secondary" sx={{ display: 'block', mr: 1, alignSelf: 'center' }}>Transitions to:</Typography>
                        {nextSteps.map(ns => (
                          <Chip key={ns} label={ns} size="small" color="info" sx={{ height: 20, fontSize: '0.65rem' }} />
                        ))}
                        {nextSteps.length === 0 && <Chip label="None (Terminal)" size="small" sx={{ height: 20, fontSize: '0.65rem' }} />}
                      </Box>
                      <Box mt={0.5} display="flex" flexWrap="wrap" gap={0.5}>
                        <Typography variant="caption" color="text.secondary" sx={{ display: 'block', mr: 1, alignSelf: 'center' }}>Allowed Roles:</Typography>
                        {allowedRoles.map(r => (
                          <Chip key={r} label={r.replace('ROLE_', '')} size="small" color="warning" sx={{ height: 20, fontSize: '0.65rem' }} />
                        ))}
                        {allowedRoles.length === 0 && <Chip label="Anyone" size="small" variant="outlined" sx={{ height: 20, fontSize: '0.65rem' }} />}
                      </Box>
                      <Divider sx={{ mt: 1.5, borderColor: '#222' }} />
                    </Box>
                  );
                })}
              </CardContent>
            </Card>
          </Grid>
        </Grid>
      )}
    </Box>
  );
}
