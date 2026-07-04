// @ts-nocheck
import React, { useState } from 'react';
import {
  Box, Card, CardContent, Typography, Grid, Button, Table, TableBody,
  TableCell, TableContainer, TableHead, TableRow, IconButton, TextField
} from '@mui/material';
import { Room, Edit, Add, Save } from '@mui/icons-material';
import MapView from '../components/MapView';

interface BranchLocation {
  id: string;
  name: string;
  lat: number;
  lng: number;
  radiusKm: number;
  deliveryFee: number;
}

export default function BranchManagement() {
  const [branches, setBranches] = useState<BranchLocation[]>([
    { id: '1', name: 'Downtown Branch 01', lat: 37.7749, lng: -122.4194, radiusKm: 5.0, deliveryFee: 3.50 },
    { id: '2', name: 'Suburb North Branch 02', lat: 37.8044, lng: -122.2712, radiusKm: 8.0, deliveryFee: 5.00 }
  ]);

  const [activeBranch, setActiveBranch] = useState<BranchLocation>(branches[0]);

  const handleUpdate = (updated: BranchLocation) => {
    setActiveBranch(updated);
    setBranches(branches.map(b => b.id === updated.id ? updated : b));
  };

  return (
    <Box>
      <Box display="flex" justifyContent="space-between" alignItems="center" mb={4}>
        <Typography variant="h4" fontWeight="bold">
          Logistics Branches
        </Typography>
        <Button variant="contained" color="primary" startIcon={<Add />}>
          Register Branch
        </Button>
      </Box>

      <Grid container spacing={3}>
        <Grid item xs={12} md={5}>
          <Card sx={{ mb: 3 }}>
            <TableContainer>
              <Table>
                <TableHead>
                  <TableRow>
                    <TableCell>Branch Name</TableCell>
                    <TableCell>Radius (Km)</TableCell>
                    <TableCell align="right">Focus</TableCell>
                  </TableRow>
                </TableHead>
                <TableBody>
                  {branches.map((branch) => (
                    <TableRow
                      key={branch.id}
                      hover
                      onClick={() => setActiveBranch(branch)}
                      selected={activeBranch.id === branch.id}
                      sx={{ cursor: 'pointer' }}
                    >
                      <TableCell fontWeight="bold">{branch.name}</TableCell>
                      <TableCell>{branch.radiusKm} km</TableCell>
                      <TableCell align="right">
                        <IconButton size="small">
                          <Room color="primary" />
                        </IconButton>
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </TableContainer>
          </Card>

          <Card>
            <CardContent sx={{ display: 'flex', flexDirection: 'column', gap: 2.5 }}>
              <Typography variant="h6" fontWeight="bold">
                Logistics & Boundary Settings
              </Typography>
              <TextField
                fullWidth
                label="Branch Name"
                value={activeBranch.name}
                onChange={(e) => handleUpdate({ ...activeBranch, name: e.target.value })}
              />
              <Grid container spacing={2}>
                <Grid item xs={6}>
                  <TextField
                    fullWidth
                    label="Latitude"
                    type="number"
                    value={activeBranch.lat}
                    onChange={(e) => handleUpdate({ ...activeBranch, lat: parseFloat(e.target.value) || 0 })}
                  />
                </Grid>
                <Grid item xs={6}>
                  <TextField
                    fullWidth
                    label="Longitude"
                    type="number"
                    value={activeBranch.lng}
                    onChange={(e) => handleUpdate({ ...activeBranch, lng: parseFloat(e.target.value) || 0 })}
                  />
                </Grid>
              </Grid>
              <Grid container spacing={2}>
                <Grid item xs={6}>
                  <TextField
                    fullWidth
                    label="Service Radius (Km)"
                    type="number"
                    value={activeBranch.radiusKm}
                    onChange={(e) => handleUpdate({ ...activeBranch, radiusKm: parseFloat(e.target.value) || 0 })}
                  />
                </Grid>
                <Grid item xs={6}>
                  <TextField
                    fullWidth
                    label="Delivery Fee ($)"
                    type="number"
                    value={activeBranch.deliveryFee}
                    onChange={(e) => handleUpdate({ ...activeBranch, deliveryFee: parseFloat(e.target.value) || 0 })}
                  />
                </Grid>
              </Grid>
              <Button variant="contained" color="primary" startIcon={<Save />}>
                Save Boundary Scope
              </Button>
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} md={7}>
          <Card sx={{ height: 'calc(100vh - 220px)', minHeight: 500 }}>
            <MapView
              latitude={activeBranch.lat}
              longitude={activeBranch.lng}
              radius={activeBranch.radiusKm * 1000}
              onMarkerDrag={(lat, lng) => handleUpdate({ ...activeBranch, lat, lng })}
            />
          </Card>
        </Grid>
      </Grid>
    </Box>
  );
}
