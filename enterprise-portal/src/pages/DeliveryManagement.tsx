// @ts-nocheck
import React, { useState } from 'react';
import {
  Box, Card, CardContent, Typography, Grid, Button, Table, TableBody,
  TableCell, TableContainer, TableHead, TableRow, Chip, Alert
} from '@mui/material';
import { DirectionsRun, CheckCircle, Warning, LocationOn } from '@mui/icons-material';

interface RiderDetails {
  id: string;
  name: string;
  vehicle: string;
  kycStatus: 'VERIFIED' | 'PENDING' | 'REJECTED';
  location: string;
  status: 'ONLINE' | 'OFFLINE' | 'DELIVERING';
}

export default function DeliveryManagement() {
  const [riders, setRiders] = useState<RiderDetails[]>([
    { id: 'R101', name: 'John Doe', vehicle: 'E-Bike (Num: EB-4592)', kycStatus: 'VERIFIED', location: 'Downtown Hub A', status: 'ONLINE' },
    { id: 'R102', name: 'Alice Smith', vehicle: 'Scooter (Num: SC-9011)', kycStatus: 'PENDING', location: 'N/A', status: 'OFFLINE' },
    { id: 'R103', name: 'Bob Johnson', vehicle: 'Car (Num: CR-0021)', kycStatus: 'VERIFIED', location: 'Suburb North Hub B', status: 'DELIVERING' }
  ]);

  const handleKycVerify = (id: string) => {
    setRiders(riders.map(r => r.id === id ? { ...r, kycStatus: 'VERIFIED' } : r));
  };

  return (
    <Box>
      <Typography variant="h4" fontWeight="bold" gutterBottom mb={4}>
        Logistics Fleets
      </Typography>

      <Grid container spacing={3}>
        <Grid item xs={12} md={8}>
          <Card>
            <CardContent>
              <Typography variant="h6" fontWeight="bold" gutterBottom>
                Active Delivery Partners
              </Typography>
              <TableContainer>
                <Table>
                  <TableHead>
                    <TableRow>
                      <TableCell>Partner ID</TableCell>
                      <TableCell>Name</TableCell>
                      <TableCell>Vehicle specifications</TableCell>
                      <TableCell>KYC Status</TableCell>
                      <TableCell>Status</TableCell>
                      <TableCell align="right">GPS Check</TableCell>
                    </TableRow>
                  </TableHead>
                  <TableBody>
                    {riders.map((rider) => (
                      <TableRow key={rider.id}>
                        <TableCell fontWeight="bold">{rider.id}</TableCell>
                        <TableCell>{rider.name}</TableCell>
                        <TableCell>{rider.vehicle}</TableCell>
                        <TableCell>
                          <Chip
                            label={rider.kycStatus}
                            size="small"
                            color={rider.kycStatus === 'VERIFIED' ? 'success' : rider.kycStatus === 'PENDING' ? 'warning' : 'error'}
                          />
                        </TableCell>
                        <TableCell>
                          <Chip
                            label={rider.status}
                            size="small"
                            variant="outlined"
                            color={rider.status === 'ONLINE' ? 'success' : rider.status === 'DELIVERING' ? 'primary' : 'default'}
                          />
                        </TableCell>
                        <TableCell align="right">
                          {rider.status !== 'OFFLINE' ? (
                            <Button size="small" startIcon={<LocationOn />}>
                              Map Track
                            </Button>
                          ) : (
                            <Typography variant="caption" color="text.secondary">N/A</Typography>
                          )}
                        </TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              </TableContainer>
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} md={4}>
          <Card>
            <CardContent sx={{ display: 'flex', flexDirection: 'column', gap: 2.5 }}>
              <Typography variant="h6" fontWeight="bold">
                KYC Verification queue
              </Typography>
              <Typography variant="body2" color="text.secondary">
                Review driver licenses, ID documents, and background check records for pending candidates.
              </Typography>
              <Divider />
              {riders.filter(r => r.kycStatus === 'PENDING').map(rider => (
                <Box key={rider.id} display="flex" flexDirection="column" gap={1.5} borderBottom="1px solid #2c2c2c" pb={2}>
                  <Box display="flex" justifyContent="space-between" alignItems="center">
                    <Typography variant="body2" fontWeight="bold">{rider.name} ({rider.id})</Typography>
                    <Chip label="Documents Pending" size="small" color="warning" />
                  </Box>
                  <Typography variant="caption" color="text.secondary">{rider.vehicle}</Typography>
                  <Box display="flex" gap={1}>
                    <Button
                      variant="contained"
                      color="primary"
                      size="small"
                      startIcon={<CheckCircle />}
                      onClick={() => handleKycVerify(rider.id)}
                    >
                      Approve Partner
                    </Button>
                    <Button variant="outlined" color="error" size="small">
                      Reject KYC
                    </Button>
                  </Box>
                </Box>
              ))}
              {riders.filter(r => r.kycStatus === 'PENDING').isEmpty() && (
                <Alert severity="success">
                  All pending KYC documents successfully reviewed!
                </Alert>
              )}
            </CardContent>
          </Card>
        </Grid>
      </Grid>
    </Box>
  );
}

// polyfill helper isEmpty
if (!Array.prototype.isEmpty) {
  Object.defineProperty(Array.prototype, 'isEmpty', {
    value: function() {
      return this.length === 0;
    }
  });
}

declare global {
  interface Array<T> {
    isEmpty(): boolean;
  }
}
