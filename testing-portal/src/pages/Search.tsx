// @ts-nocheck
import React, { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { Box, Typography, TextField, Card, CardContent, Alert, Grid, Chip, Divider } from '@mui/material';
import { getProducts, getCategories } from '../api/portal';

export default function Search() {
  const { data: products = [] } = useQuery({ queryKey: ['products'], queryFn: getProducts });
  const { data: cats = [] } = useQuery({ queryKey: ['categories'], queryFn: getCategories });
  const [query, setQuery] = useState('');

  const filtered = query.trim().length > 0
    ? products.filter((p: any) =>
        p.name?.toLowerCase().includes(query.toLowerCase()) ||
        p.description?.toLowerCase().includes(query.toLowerCase()) ||
        p.categoryId?.toLowerCase().includes(query.toLowerCase())
      )
    : [];

  const catLabel = (id: string) => cats.find((c: any) => c.id === id)?.label ?? id;

  return (
    <Box>
      <Typography variant="h5" fontWeight={700} sx={{ mb: 0.5 }}>Search Simulator</Typography>
      <Typography color="text.secondary" fontSize="0.85rem" sx={{ mb: 3 }}>
        Test search results as the customer app would see them. Search across product names, descriptions, and categories.
      </Typography>

      <TextField
        fullWidth
        label="Search products, categories..."
        value={query}
        onChange={e => setQuery(e.target.value)}
        autoFocus
        sx={{ mb: 3 }}
        helperText={`${products.length} products indexed · ${cats.length} categories`}
      />

      {query.trim().length === 0 && (
        <Box>
          <Typography fontWeight={600} sx={{ mb: 2 }}>All Categories ({cats.length})</Typography>
          <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 1, mb: 3 }}>
            {cats.map((c: any) => (
              <Chip key={c.id} label={`${c.iconUrl} ${c.label}`} onClick={() => setQuery(c.label)} clickable
                color={c.isAvailable ? 'default' : 'error'}
                sx={{ bgcolor: '#1f2937', fontWeight: 600 }}
              />
            ))}
          </Box>

          <Typography fontWeight={600} sx={{ mb: 2 }}>All Products ({products.length})</Typography>
          <Grid container spacing={1.5}>
            {products.map((p: any) => (
              <Grid item xs={12} sm={6} md={4} key={p.id}>
                <Card sx={{ cursor: 'pointer', '&:hover': { borderColor: '#6366f1' } }} onClick={() => setQuery(p.name)}>
                  <CardContent sx={{ p: 2 }}>
                    <Box sx={{ display: 'flex', justifyContent: 'space-between' }}>
                      <Typography fontWeight={600} fontSize="0.85rem">{p.name}</Typography>
                      <Typography fontWeight={700} color="primary.light" fontSize="0.85rem">${p.price}</Typography>
                    </Box>
                    <Chip label={catLabel(p.categoryId)} size="small" sx={{ mt: 0.5 }} />
                    {!p.isAvailable && <Chip label="OOS" size="small" color="error" sx={{ ml: 0.5, mt: 0.5 }} />}
                  </CardContent>
                </Card>
              </Grid>
            ))}
          </Grid>
        </Box>
      )}

      {query.trim().length > 0 && (
        <Box>
          <Typography fontWeight={600} sx={{ mb: 2 }}>
            Results for "{query}" — {filtered.length} match{filtered.length !== 1 ? 'es' : ''}
          </Typography>
          {filtered.length === 0 ? (
            <Alert severity="warning">No products match "{query}". This is what the customer app's empty state looks like.</Alert>
          ) : (
            <Grid container spacing={1.5}>
              {filtered.map((p: any) => (
                <Grid item xs={12} sm={6} md={4} key={p.id}>
                  <Card>
                    <CardContent sx={{ p: 2 }}>
                      <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 0.5 }}>
                        <Typography fontWeight={700} fontSize="0.9rem">{p.name}</Typography>
                        <Typography fontWeight={700} color="success.main" fontSize="0.9rem">${p.price}</Typography>
                      </Box>
                      {p.description && <Typography fontSize="0.78rem" color="text.secondary" sx={{ mb: 0.8 }}>{p.description}</Typography>}
                      <Box sx={{ display: 'flex', gap: 0.5, flexWrap: 'wrap' }}>
                        <Chip label={catLabel(p.categoryId)} size="small" />
                        <Chip label={p.isAvailable ? 'Available' : 'OOS'} size="small" color={p.isAvailable ? 'success' : 'error'} />
                        {p.stock !== undefined && <Chip label={`${p.stock} left`} size="small" />}
                      </Box>
                    </CardContent>
                  </Card>
                </Grid>
              ))}
            </Grid>
          )}
        </Box>
      )}
    </Box>
  );
}
