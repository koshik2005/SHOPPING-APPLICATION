// @ts-nocheck
import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import {
  Box, Typography, Grid, Card, CardContent, CardActions, Chip, Button,
  Alert, Snackbar, Stack, Divider, MenuItem, TextField,
} from '@mui/material';
import { DeliveryDining, LocationOn, MyLocation } from '@mui/icons-material';
import MapView from '../components/MapView';
import { getPartners, moveRider } from '../api/portal';

export default function Delivery() {
  const qc = useQueryClient();
  const { data: partners = [] } = useQuery({ queryKey: ['partners'], queryFn: getPartners, refetchInterval: 3000 });
  const [selected, setSelected] = useState<string | null>(null);
  const [snack, setSnack] = useState('');
  const [manualLat, setManualLat] = useState('37.7749');
  const [manualLng, setManualLng] = useState('-122.4194');

  const moveM = useMutation({
    mutationFn: ({ partnerId, lat, lng }: any) => moveRider(partnerId, lat, lng),
    onSuccess: () => { qc.invalidateQueries({ queryKey: ['partners'] }); setSnack('Rider location updated!'); }
  });

  const selectedPartner = partners.find((p: any) => p.id === selected);

  const mapMarkers = partners.map((p: any) => ({
    lat: p.latitude ?? 37.7749,
    lng: p.longitude ?? -122.4194,
    label: `${p.name ?? p.id} (${p.status ?? 'UNKNOWN'})`,
    color: p.id === selected ? '#6366f1' : '#06b6d4',
    draggable: p.id === selected,
    onDrag: (lat: number, lng: number) => {
      if (p.id === selected) {
        moveM.mutate({ partnerId: p.id, lat, lng });
      }
    },
  }));

  return (
    <Box>
      <Box sx={{ mb: 3 }}>
        <Typography variant="h5" fontWeight={700}>Delivery GPS Simulator</Typography>
        <Typography color="text.secondary" fontSize="0.85rem">Select a delivery partner and drag their marker on the map to simulate GPS movement.</Typography>
      </Box>

      <Grid container spacing={2}>
        <Grid item xs={12} md={5}>
          {partners.length === 0 ? (
            <Alert severity="info">No delivery partners found. Register a delivery partner via the Delivery portal first.</Alert>
          ) : (
            <Stack spacing={1.5}>
              {partners.map((p: any) => (
                <Card
                  key={p.id}
                  onClick={() => setSelected(p.id)}
                  sx={{ cursor: 'pointer', border: selected === p.id ? '2px solid #6366f1' : '1px solid #1f2937' }}
                >
                  <CardContent sx={{ p: 2 }}>
                    <Box sx={{ display: 'flex', justifyContent: 'space-between' }}>
                      <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                        <DeliveryDining sx={{ color: selected === p.id ? '#6366f1' : '#6b7280' }} />
                        <Box>
                          <Typography fontWeight={600} fontSize="0.9rem">{p.name ?? p.id}</Typography>
                          <Typography fontSize="0.75rem" color="text.secondary">{p.phone ?? p.mobileNumber}</Typography>
                        </Box>
                      </Box>
                      <Chip label={p.status ?? 'UNKNOWN'} size="small" color={p.status === 'ONLINE' ? 'success' : p.status === 'DELIVERING' ? 'primary' : 'default'} />
                    </Box>
                    {(p.latitude || p.longitude) && (
                      <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5, mt: 1 }}>
                        <LocationOn sx={{ fontSize: 13, color: '#6b7280' }} />
                        <Typography fontSize="0.7rem" color="text.secondary">
                          {(p.latitude ?? 0).toFixed(5)}, {(p.longitude ?? 0).toFixed(5)}
                        </Typography>
                      </Box>
                    )}
                  </CardContent>
                </Card>
              ))}
            </Stack>
          )}

          {/* Manual coordinate input */}
          {selected && (
            <Box sx={{ mt: 2, p: 2, bgcolor: '#0d1525', borderRadius: 2, border: '1px solid #1f2937' }}>
              <Typography fontWeight={600} fontSize="0.85rem" sx={{ mb: 1.5 }}>Set Exact Coordinates</Typography>
              <Stack direction="row" spacing={1}>
                <TextField label="Latitude" size="small" value={manualLat} onChange={e => setManualLat(e.target.value)} sx={{ flex: 1 }} />
                <TextField label="Longitude" size="small" value={manualLng} onChange={e => setManualLng(e.target.value)} sx={{ flex: 1 }} />
              </Stack>
              <Button
                variant="contained" fullWidth sx={{ mt: 1 }} startIcon={<MyLocation />}
                onClick={() => moveM.mutate({ partnerId: selected, lat: parseFloat(manualLat), lng: parseFloat(manualLng) })}
              >
                Move Rider Here
              </Button>
            </Box>
          )}
        </Grid>

        <Grid item xs={12} md={7}>
          <Box>
            <Typography fontWeight={600} fontSize="0.85rem" sx={{ mb: 1 }}>
              {selected ? `Drag ${selectedPartner?.name ?? selected}'s marker to simulate GPS` : 'Select a partner to enable dragging'}
            </Typography>
            <MapView
              center={[37.7749, -122.4194]}
              zoom={13}
              markers={mapMarkers}
              height={480}
            />
          </Box>
        </Grid>
      </Grid>

      <Snackbar open={!!snack} autoHideDuration={3000} onClose={() => setSnack('')} message={snack} anchorOrigin={{ vertical: 'bottom', horizontal: 'right' }} />
    </Box>
  );
}
