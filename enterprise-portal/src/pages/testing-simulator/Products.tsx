// @ts-nocheck
import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import {
  Box, Typography, Button, Table, TableHead, TableBody, TableRow, TableCell,
  Dialog, DialogTitle, DialogContent, DialogActions, TextField, Switch, Chip,
  FormControlLabel, Snackbar, Stack, MenuItem, Paper, Tooltip, IconButton, Grid,
} from '@mui/material';
import { Add, Edit, Delete, ToggleOff, ToggleOn } from '@mui/icons-material';
import { getProducts, getCategories, createProduct, updateProduct, toggleProduct, deleteProduct } from '../../api/portal';

const EMPTY = { name: '', description: '', categoryId: '', price: 10, discountPrice: '', taxRate: 0, stock: 100, imageUrl: '', isAvailable: true };

export default function Products() {
  const qc = useQueryClient();
  const { data: products = [] } = useQuery({ queryKey: ['products'], queryFn: getProducts });
  const { data: cats = [] } = useQuery({ queryKey: ['categories'], queryFn: getCategories });
  const [open, setOpen] = useState(false);
  const [form, setForm] = useState<any>(EMPTY);
  const [editing, setEditing] = useState(false);
  const [snack, setSnack] = useState('');

  const createM = useMutation({ mutationFn: createProduct, onSuccess: () => { qc.invalidateQueries({ queryKey: ['products'] }); setOpen(false); setSnack('Product created!'); } });
  const updateM = useMutation({ mutationFn: updateProduct, onSuccess: () => { qc.invalidateQueries({ queryKey: ['products'] }); setOpen(false); setSnack('Product updated!'); } });
  const toggleM = useMutation({ mutationFn: toggleProduct, onSuccess: () => { qc.invalidateQueries({ queryKey: ['products'] }); setSnack('Product toggled!'); } });
  const deleteM = useMutation({ mutationFn: deleteProduct, onSuccess: () => { qc.invalidateQueries({ queryKey: ['products'] }); setSnack('Product deleted!'); } });

  const set = (k: string, v: any) => setForm((f: any) => ({ ...f, [k]: v }));
  const save = () => editing ? updateM.mutate(form) : createM.mutate(form);

  const catLabel = (id: string) => cats.find((c: any) => c.id === id)?.label ?? id;

  return (
    <Box>
      <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 3 }}>
        <Box>
          <Typography variant="h5" fontWeight={700}>Product Simulator</Typography>
          <Typography color="text.secondary" fontSize="0.85rem">Full product CRUD. Price changes and availability toggles are reflected immediately.</Typography>
        </Box>
        <Button variant="contained" startIcon={<Add />} onClick={() => { setForm(EMPTY); setEditing(false); setOpen(true); }}>New Product</Button>
      </Box>

      <Paper>
        <Table size="small">
          <TableHead>
            <TableRow>
              <TableCell>Name</TableCell>
              <TableCell>Category</TableCell>
              <TableCell align="right">Price</TableCell>
              <TableCell align="right">Stock</TableCell>
              <TableCell>Status</TableCell>
              <TableCell>Actions</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {products.map((p: any) => (
              <TableRow key={p.id} sx={{ opacity: p.isAvailable ? 1 : 0.5 }}>
                <TableCell>
                  <Typography fontWeight={600} fontSize="0.85rem">{p.name}</Typography>
                  {p.description && <Typography fontSize="0.72rem" color="text.secondary">{p.description}</Typography>}
                </TableCell>
                <TableCell>
                  <Chip label={catLabel(p.categoryId) || p.categoryId} size="small" />
                </TableCell>
                <TableCell align="right">
                  <Typography fontWeight={600}>${p.price}</Typography>
                  {p.discountPrice && <Typography fontSize="0.72rem" color="success.main">${p.discountPrice} sale</Typography>}
                </TableCell>
                <TableCell align="right">
                  <Chip label={p.stock ?? '∞'} size="small" color={!p.stock || p.stock === 0 ? 'error' : p.stock < 10 ? 'warning' : 'default'} />
                </TableCell>
                <TableCell>
                  <Chip label={p.isAvailable ? 'Available' : 'OOS'} size="small" color={p.isAvailable ? 'success' : 'error'} />
                </TableCell>
                <TableCell>
                  <Box sx={{ display: 'flex', gap: 0.5 }}>
                    <Tooltip title="Edit"><IconButton size="small" onClick={() => { setForm({ ...p }); setEditing(true); setOpen(true); }}><Edit fontSize="small" /></IconButton></Tooltip>
                    <Tooltip title="Toggle"><IconButton size="small" onClick={() => toggleM.mutate(p.id)} color={p.isAvailable ? 'warning' : 'success'}><ToggleOff fontSize="small" /></IconButton></Tooltip>
                    <Tooltip title="Delete"><IconButton size="small" color="error" onClick={() => deleteM.mutate(p.id)}><Delete fontSize="small" /></IconButton></Tooltip>
                  </Box>
                </TableCell>
              </TableRow>
            ))}
            {products.length === 0 && (
              <TableRow>
                <TableCell colSpan={6} align="center" sx={{ py: 4, color: '#4b5563' }}>No products configured</TableCell>
              </TableRow>
            )}
          </TableBody>
        </Table>
      </Paper>

      <Dialog open={open} onClose={() => setOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle>{editing ? 'Edit Product' : 'Create Product'}</DialogTitle>
        <DialogContent>
          <Stack spacing={2} sx={{ mt: 1 }}>
            <TextField label="Product Name" value={form.name ?? ''} onChange={e => set('name', e.target.value)} fullWidth required />
            <TextField label="Description" value={form.description ?? ''} onChange={e => set('description', e.target.value)} fullWidth multiline rows={2} />
            <TextField label="Category" value={form.categoryId ?? ''} onChange={e => set('categoryId', e.target.value)} fullWidth select>
              {cats.map((c: any) => <MenuItem key={c.id} value={c.id}>{c.iconUrl} {c.label}</MenuItem>)}
            </TextField>
            <Grid container spacing={2}>
              <Grid item xs={6}><TextField label="Price ($)" type="number" value={form.price ?? ''} onChange={e => set('price', parseFloat(e.target.value))} fullWidth /></Grid>
              <Grid item xs={6}><TextField label="Discount Price ($)" type="number" value={form.discountPrice ?? ''} onChange={e => set('discountPrice', e.target.value || null)} fullWidth /></Grid>
            </Grid>
            <Grid container spacing={2}>
              <Grid item xs={6}><TextField label="Stock" type="number" value={form.stock ?? ''} onChange={e => set('stock', parseInt(e.target.value))} fullWidth /></Grid>
              <Grid item xs={6}><TextField label="Tax Rate" type="number" value={form.taxRate ?? ''} onChange={e => set('taxRate', parseFloat(e.target.value))} fullWidth /></Grid>
            </Grid>
            <TextField label="Image URL" value={form.imageUrl ?? ''} onChange={e => set('imageUrl', e.target.value)} fullWidth />
            <FormControlLabel control={<Switch checked={!!form.isAvailable} onChange={e => set('isAvailable', e.target.checked)} color="success" />} label="Available in App" />
          </Stack>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setOpen(false)}>Cancel</Button>
          <Button variant="contained" onClick={save} disabled={createM.isPending || updateM.isPending}>{editing ? 'Update' : 'Create'}</Button>
        </DialogActions>
      </Dialog>

      <Snackbar open={!!snack} autoHideDuration={3000} onClose={() => setSnack('')} message={snack} anchorOrigin={{ vertical: 'bottom', horizontal: 'right' }} />
    </Box>
  );
}


