// @ts-nocheck
import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import {
  Box, Typography, Card, CardContent, Grid, TextField, Button,
  Stack, Snackbar, Chip, Slider, Alert,
} from '@mui/material';
import { MyLocation, ZoomIn, ZoomOut } from '@mui/icons-material';
import MapView from '../components/MapView';
import { getBranches, updateBranch, getPartners, moveRider } from '../api/portal';

export default function Location() {
  const qc = useQueryClient();
  const { data: branches = [] } = useQuery({ queryKey: ['branches'], queryFn: getBranches });
  const { data: partners = [] } = useQuery({ queryKey: ['partners'], queryFn: getPartners, refetchInterval: 3000 });
  const [snack, setSnack] = useState('');

  const updateBranchM = useMutation({
    mutationFn: ({ id, ...d }: any) => updateBranch({ id, ...d }),
    onSuccess: () => { qc.invalidateQueries({ queryKey: ['branches'] }); setSnack('Branch location updated!'); }
  });

  // Build map markers
  const branchMarkers = branches.map((b: any) => ({
    lat: b.latitude ?? 37.7749,
    lng: b.longitude ?? -122.4194,
    label: `🏪 ${b.name}`,
    color: '#06b6d4',
    draggable: true,
    onDrag: (lat: number, lng: number) => {
      updateBranchM.mutate({ id: b.id, latitude: lat, longitude: lng });
    },
  }));

  const riderMarkers = partners.map((p: any) => ({
    lat: p.latitude ?? 37.7749,
    lng: p.longitude ?? -122.4194,
    label: `🛵 ${p.name}`,
    color: '#6366f1',
  }));

  const circles = branches.map((b: any) => ({
    lat: b.latitude ?? 37.7749,
    lng: b.longitude ?? -122.4194,
    radiusKm: b.servingRadiusKm ?? 5,
    color: '#06b6d4',
  }));

  return (
    <Box>
      <Box sx={{ mb: 3 }}>
        <Typography variant="h5" fontWeight={700}>Location Simulator</Typography>
        <Typography color="text.secondary" fontSize="0.85rem">
          Drag branch markers (cyan) to reposition. Rider markers (purple) auto-update from GPS simulator.
          The shaded circles show each branch's serving radius.
        </Typography>
      </Box>

      <Grid container spacing={2}>
        <Grid item xs={12} md={8}>
          <Box sx={{ mb: 1.5, display: 'flex', gap: 1 }}>
            <Chip size="small" label="🏪 Branch (draggable)" sx={{ bgcolor: '#06b6d420', color: '#06b6d4', border: '1px solid #06b6d440' }} />
            <Chip size="small" label="🛵 Rider (read-only)" sx={{ bgcolor: '#6366f120', color: '#818cf8', border: '1px solid #6366f140' }} />
            <Chip size="small" label="⭕ Serving radius" sx={{ bgcolor: '#1f2937', color: '#9ca3af', border: '1px solid #374151' }} />
          </Box>
          <MapView
            center={[37.7749, -122.4194]}
            zoom={12}
            markers={[...branchMarkers, ...riderMarkers]}
            circles={circles}
            height={520}
          />
        </Grid>

        <Grid item xs={12} md={4}>
          <Typography fontWeight={700} sx={{ mb: 1.5 }}>Branch Details</Typography>
          <Stack spacing={1.5}>
            {branches.length === 0 && (
              <Alert severity="info">No branches. Go to Branches to create one.</Alert>
            )}
            {branches.map((b: any) => (
              <Card key={b.id}>
                <CardContent sx={{ p: 2 }}>
                  <Typography fontWeight={700} fontSize="0.9rem">{b.name}</Typography>
                  <Typography fontSize="0.75rem" color="text.secondary" sx={{ mt: 0.3 }}>
                    {(b.latitude ?? 37.7749).toFixed(5)}, {(b.longitude ?? -122.4194).toFixed(5)}
                  </Typography>
                  <Box sx={{ mt: 1.5 }}>
                    <Typography fontSize="0.75rem" color="text.secondary" sx={{ mb: 0.5 }}>
                      Serving Radius: {b.servingRadiusKm ?? 5} km
                    </Typography>
                    <Slider
                      value={b.servingRadiusKm ?? 5}
                      min={1} max={25} step={0.5}
                      onChange={(_, v) => updateBranchM.mutate({ id: b.id, servingRadiusKm: v })}
                      valueLabelDisplay="auto"
                      valueLabelFormat={v => `${v}km`}
                      sx={{ '& .MuiSlider-track': { background: 'linear-gradient(90deg, #06b6d4, #6366f1)' } }}
                    />
                  </Box>
                </CardContent>
              </Card>
            ))}
          </Stack>
        </Grid>
      </Grid>

      <Snackbar open={!!snack} autoHideDuration={3000} onClose={() => setSnack('')} message={snack} anchorOrigin={{ vertical: 'bottom', horizontal: 'right' }} />
    </Box>
  );
}
