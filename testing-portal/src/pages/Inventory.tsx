// @ts-nocheck
import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import {
  Box, Typography, Card, CardContent, Grid, Chip, IconButton, Slider,
  TextField, Button, Stack, Snackbar, Alert, Divider, Tooltip,
} from '@mui/material';
import { Add, Remove, WarningAmber, CheckCircle, Block } from '@mui/icons-material';
import { getProducts, adjustInventory } from '../api/portal';

export default function Inventory() {
  const qc = useQueryClient();
  const { data: products = [] } = useQuery({ queryKey: ['products'], queryFn: getProducts });
  const [snack, setSnack] = useState('');
  const [setValues, setSetValues] = useState<Record<string, string>>({});

  const adjustM = useMutation({
    mutationFn: ({ id, delta, setTo }: any) => adjustInventory(id, delta, setTo),
    onSuccess: () => { qc.invalidateQueries({ queryKey: ['products'] }); setSnack('Stock updated!'); }
  });

  const handleSet = (id: string) => {
    const val = parseInt(setValues[id] ?? '0');
    if (!isNaN(val)) adjustM.mutate({ id, setTo: val });
  };

  return (
    <Box>
      <Box sx={{ mb: 3 }}>
        <Typography variant="h5" fontWeight={700}>Inventory Simulator</Typography>
        <Typography color="text.secondary" fontSize="0.85rem">Adjust stock levels per product. Stock reaching 0 auto-marks product as Out of Stock.</Typography>
      </Box>

      {products.length === 0 && (
        <Alert severity="info">No products found. Go to Products module to create some.</Alert>
      )}

      <Grid container spacing={2}>
        {products.map((p: any) => {
          const stock = p.stock ?? 0;
          const stockColor = stock === 0 ? '#ef4444' : stock < 10 ? '#f59e0b' : '#10b981';
          return (
            <Grid item xs={12} sm={6} md={4} key={p.id}>
              <Card>
                <CardContent>
                  <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', mb: 1.5 }}>
                    <Box>
                      <Typography fontWeight={700} fontSize="0.9rem">{p.name}</Typography>
                      <Typography fontSize="0.75rem" color="text.secondary">${p.price}</Typography>
                    </Box>
                    <Chip
                      label={stock === 0 ? 'OUT OF STOCK' : `${stock} in stock`}
                      size="small"
                      icon={stock === 0 ? <Block fontSize="small" /> : stock < 10 ? <WarningAmber fontSize="small" /> : <CheckCircle fontSize="small" />}
                      sx={{ bgcolor: `${stockColor}1a`, color: stockColor, border: `1px solid ${stockColor}40`, fontWeight: 700 }}
                    />
                  </Box>

                  {/* Stock bar */}
                  <Box sx={{ mb: 2 }}>
                    <Slider
                      value={Math.min(stock, 200)}
                      min={0} max={200}
                      disabled
                      sx={{ '& .MuiSlider-rail': { bgcolor: '#1f2937' }, '& .MuiSlider-track': { bgcolor: stockColor }, '& .MuiSlider-thumb': { display: 'none' }, py: 0 }}
                    />
                  </Box>

                  {/* Adjustment controls */}
                  <Stack direction="row" spacing={1} alignItems="center" sx={{ mb: 1.5 }}>
                    <Tooltip title="Remove 5">
                      <IconButton size="small" onClick={() => adjustM.mutate({ id: p.id, delta: -5 })} sx={{ bgcolor: '#1f2937' }}>
                        <Remove fontSize="small" />
                      </IconButton>
                    </Tooltip>
                    <Tooltip title="Remove 1">
                      <IconButton size="small" onClick={() => adjustM.mutate({ id: p.id, delta: -1 })} sx={{ bgcolor: '#1f2937' }}>
                        <Remove fontSize="small" sx={{ fontSize: 12 }} />
                      </IconButton>
                    </Tooltip>
                    <Typography sx={{ flex: 1, textAlign: 'center', fontWeight: 700, fontSize: '1.1rem', color: stockColor }}>
                      {stock}
                    </Typography>
                    <Tooltip title="Add 1">
                      <IconButton size="small" onClick={() => adjustM.mutate({ id: p.id, delta: 1 })} sx={{ bgcolor: '#1f2937' }}>
                        <Add fontSize="small" sx={{ fontSize: 12 }} />
                      </IconButton>
                    </Tooltip>
                    <Tooltip title="Add 10">
                      <IconButton size="small" onClick={() => adjustM.mutate({ id: p.id, delta: 10 })} sx={{ bgcolor: '#1f2937' }}>
                        <Add fontSize="small" />
                      </IconButton>
                    </Tooltip>
                  </Stack>

                  <Divider sx={{ my: 1, borderColor: '#1f2937' }} />

                  {/* Set exact value */}
                  <Stack direction="row" spacing={1} alignItems="center">
                    <TextField
                      label="Set to"
                      type="number"
                      size="small"
                      value={setValues[p.id] ?? ''}
                      onChange={e => setSetValues(v => ({ ...v, [p.id]: e.target.value }))}
                      sx={{ flex: 1 }}
                    />
                    <Button variant="outlined" size="small" onClick={() => handleSet(p.id)}>Set</Button>
                    <Button variant="outlined" size="small" color="error" onClick={() => adjustM.mutate({ id: p.id, setTo: 0 })}>OOS</Button>
                    <Button variant="outlined" size="small" color="success" onClick={() => adjustM.mutate({ id: p.id, setTo: 100 })}>+100</Button>
                  </Stack>
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
