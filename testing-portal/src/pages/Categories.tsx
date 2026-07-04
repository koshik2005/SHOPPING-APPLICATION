// @ts-nocheck
import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import {
  Box, Typography, Button, Grid, Card, CardContent, CardActions, Chip, IconButton,
  Dialog, DialogTitle, DialogContent, DialogActions, TextField, Switch,
  FormControlLabel, Snackbar, Stack, Alert,
} from '@mui/material';
import { Add, Delete, Edit, CheckCircle, Cancel } from '@mui/icons-material';
import { getCategories, createCategory, updateCategory, deleteCategory } from '../api/portal';

const EMOJIS = ['🍕', '🛒', '💊', '🥤', '🛍', '📦', '🍔', '🧴', '🏪', '🌿', '🥗', '🎂', '🍱', '🚿', '🔧', '📱', '👕', '🌸', '🐾', '🏋️'];
const EMPTY = { label: '', iconUrl: '📦', isAvailable: true, displayOrder: 99 };

export default function Categories() {
  const qc = useQueryClient();
  const { data: cats = [], isLoading } = useQuery({ queryKey: ['categories'], queryFn: getCategories });
  const [open, setOpen] = useState(false);
  const [form, setForm] = useState<any>(EMPTY);
  const [editing, setEditing] = useState(false);
  const [snack, setSnack] = useState('');

  const createM = useMutation({ mutationFn: createCategory, onSuccess: () => { qc.invalidateQueries({ queryKey: ['categories'] }); setOpen(false); setSnack('Category created!'); } });
  const updateM = useMutation({ mutationFn: updateCategory, onSuccess: () => { qc.invalidateQueries({ queryKey: ['categories'] }); setOpen(false); setSnack('Category updated!'); } });
  const deleteM = useMutation({ mutationFn: deleteCategory, onSuccess: () => { qc.invalidateQueries({ queryKey: ['categories'] }); setSnack('Category deleted!'); } });
  const toggleM = useMutation({
    mutationFn: (cat: any) => updateCategory({ id: cat.id, isAvailable: !cat.isAvailable }),
    onSuccess: () => { qc.invalidateQueries({ queryKey: ['categories'] }); setSnack('Category toggled!'); }
  });

  const set = (k: string, v: any) => setForm((f: any) => ({ ...f, [k]: v }));
  const save = () => editing ? updateM.mutate(form) : createM.mutate(form);

  return (
    <Box>
      <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 3 }}>
        <Box>
          <Typography variant="h5" fontWeight={700}>Category Simulator</Typography>
          <Typography color="text.secondary" fontSize="0.85rem">Add, edit, and toggle categories. They appear immediately in the customer app's home screen.</Typography>
        </Box>
        <Button variant="contained" startIcon={<Add />} onClick={() => { setForm(EMPTY); setEditing(false); setOpen(true); }}>New Category</Button>
      </Box>

      {cats.length === 0 && !isLoading && (
        <Alert severity="info" sx={{ mb: 2 }}>No categories. Create one to see it in the customer app!</Alert>
      )}

      <Grid container spacing={2}>
        {[...cats].sort((a: any, b: any) => (a.displayOrder ?? 99) - (b.displayOrder ?? 99)).map((c: any) => (
          <Grid item xs={12} sm={6} md={4} lg={3} key={c.id}>
            <Card sx={{ opacity: c.isAvailable ? 1 : 0.5 }}>
              <CardContent>
                <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 1.5 }}>
                  <Typography fontSize="2.5rem" lineHeight={1}>{c.iconUrl}</Typography>
                  <Chip label={c.isAvailable ? 'Available' : 'Hidden'} size="small" color={c.isAvailable ? 'success' : 'default'} />
                </Box>
                <Typography fontWeight={700} fontSize="1rem">{c.label}</Typography>
                <Typography fontSize="0.75rem" color="text.secondary">ID: {c.id}</Typography>
                <Typography fontSize="0.75rem" color="text.secondary">Order: #{c.displayOrder}</Typography>
              </CardContent>
              <CardActions sx={{ px: 2, pb: 2, gap: 1 }}>
                <Button size="small" startIcon={<Edit />} onClick={() => { setForm({ ...c }); setEditing(true); setOpen(true); }} variant="outlined">Edit</Button>
                <Button size="small" startIcon={c.isAvailable ? <Cancel /> : <CheckCircle />} onClick={() => toggleM.mutate(c)} variant="outlined" color={c.isAvailable ? 'warning' : 'success'}>
                  {c.isAvailable ? 'Hide' : 'Show'}
                </Button>
                <Button size="small" startIcon={<Delete />} onClick={() => deleteM.mutate(c.id)} color="error" variant="outlined">Del</Button>
              </CardActions>
            </Card>
          </Grid>
        ))}
      </Grid>

      <Dialog open={open} onClose={() => setOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle>{editing ? 'Edit Category' : 'Create Category'}</DialogTitle>
        <DialogContent>
          <Stack spacing={2} sx={{ mt: 1 }}>
            <TextField label="Category Label" value={form.label ?? ''} onChange={e => set('label', e.target.value)} fullWidth required />
            <Box>
              <Typography fontSize="0.8rem" color="text.secondary" sx={{ mb: 1 }}>Emoji Icon</Typography>
              <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 0.8 }}>
                {EMOJIS.map(e => (
                  <Box
                    key={e} onClick={() => set('iconUrl', e)}
                    sx={{ fontSize: '1.5rem', cursor: 'pointer', p: 0.5, borderRadius: 1.5, border: form.iconUrl === e ? '2px solid #6366f1' : '2px solid transparent', bgcolor: form.iconUrl === e ? 'rgba(99,102,241,0.1)' : 'transparent', '&:hover': { bgcolor: 'rgba(255,255,255,0.05)' } }}
                  >{e}</Box>
                ))}
              </Box>
            </Box>
            <TextField label="Custom Icon/Emoji" value={form.iconUrl ?? ''} onChange={e => set('iconUrl', e.target.value)} fullWidth size="small" />
            <TextField label="Display Order" type="number" value={form.displayOrder ?? 99} onChange={e => set('displayOrder', parseInt(e.target.value))} fullWidth />
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
