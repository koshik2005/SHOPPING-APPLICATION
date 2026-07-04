// @ts-nocheck
import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import {
  Box, Typography, Button, Table, TableHead, TableBody, TableRow, TableCell,
  Dialog, DialogTitle, DialogContent, DialogActions, TextField, Chip,
  Snackbar, Stack, Paper, MenuItem, Tooltip, IconButton, Alert,
} from '@mui/material';
import { Add, PersonOff, Person, Delete } from '@mui/icons-material';
import { getUsers, createUser, manageUser } from '../api/portal';

export default function Users() {
  const qc = useQueryClient();
  const { data: users = [] } = useQuery({ queryKey: ['users'], queryFn: getUsers });
  const [open, setOpen] = useState(false);
  const [form, setForm] = useState({ name: '', email: '', mobileNumber: '', role: 'CUSTOMER' });
  const [snack, setSnack] = useState('');

  const createM = useMutation({ mutationFn: createUser, onSuccess: () => { qc.invalidateQueries({ queryKey: ['users'] }); setOpen(false); setSnack('User created!'); } });
  const manageM = useMutation({ mutationFn: ({ email, action }: any) => manageUser(email, action), onSuccess: (_, { action }) => { qc.invalidateQueries({ queryKey: ['users'] }); setSnack(`User ${action.toLowerCase()}d!`); } });

  const set = (k: string, v: string) => setForm(f => ({ ...f, [k]: v }));

  return (
    <Box>
      <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 3 }}>
        <Box>
          <Typography variant="h5" fontWeight={700}>User Simulator</Typography>
          <Typography color="text.secondary" fontSize="0.85rem">Create, suspend, and activate platform users.</Typography>
        </Box>
        <Button variant="contained" startIcon={<Add />} onClick={() => setOpen(true)}>Create User</Button>
      </Box>

      {users.length === 0 && (
        <Alert severity="info" sx={{ mb: 2 }}>No users registered yet. Users appear here after authentication.</Alert>
      )}

      <Paper>
        <Table size="small">
          <TableHead>
            <TableRow>
              <TableCell>Name</TableCell>
              <TableCell>Email</TableCell>
              <TableCell>Mobile</TableCell>
              <TableCell>Role</TableCell>
              <TableCell>Status</TableCell>
              <TableCell>Created</TableCell>
              <TableCell>Actions</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {users.map((u: any) => (
              <TableRow key={u.email}>
                <TableCell>
                  <Typography fontWeight={600} fontSize="0.85rem">{u.name}</Typography>
                </TableCell>
                <TableCell>
                  <Typography fontSize="0.8rem" color="text.secondary">{u.email}</Typography>
                </TableCell>
                <TableCell>
                  <Typography fontSize="0.8rem">{u.mobileNumber}</Typography>
                </TableCell>
                <TableCell>
                  <Chip label={u.role ?? 'CUSTOMER'} size="small" color={u.role === 'ADMIN' ? 'primary' : 'default'} />
                </TableCell>
                <TableCell>
                  <Chip
                    label={u.status ?? 'ACTIVE'}
                    size="small"
                    color={u.status === 'SUSPENDED' ? 'error' : 'success'}
                  />
                </TableCell>
                <TableCell>
                  <Typography fontSize="0.72rem" color="text.secondary">{u.createdAt?.slice(0, 10) ?? '—'}</Typography>
                </TableCell>
                <TableCell>
                  <Box sx={{ display: 'flex', gap: 0.5 }}>
                    {u.status === 'SUSPENDED' ? (
                      <Tooltip title="Activate"><IconButton size="small" color="success" onClick={() => manageM.mutate({ email: u.email, action: 'ACTIVATE' })}><Person fontSize="small" /></IconButton></Tooltip>
                    ) : (
                      <Tooltip title="Suspend"><IconButton size="small" color="warning" onClick={() => manageM.mutate({ email: u.email, action: 'SUSPEND' })}><PersonOff fontSize="small" /></IconButton></Tooltip>
                    )}
                    <Tooltip title="Delete"><IconButton size="small" color="error" onClick={() => manageM.mutate({ email: u.email, action: 'DELETE' })}><Delete fontSize="small" /></IconButton></Tooltip>
                  </Box>
                </TableCell>
              </TableRow>
            ))}
            {users.length === 0 && (
              <TableRow><TableCell colSpan={7} align="center" sx={{ py: 4, color: '#4b5563' }}>No users</TableCell></TableRow>
            )}
          </TableBody>
        </Table>
      </Paper>

      <Dialog open={open} onClose={() => setOpen(false)} maxWidth="xs" fullWidth>
        <DialogTitle>Create Test User</DialogTitle>
        <DialogContent>
          <Stack spacing={2} sx={{ mt: 1 }}>
            <TextField label="Full Name" value={form.name} onChange={e => set('name', e.target.value)} fullWidth />
            <TextField label="Email" type="email" value={form.email} onChange={e => set('email', e.target.value)} fullWidth required />
            <TextField label="Mobile Number" value={form.mobileNumber} onChange={e => set('mobileNumber', e.target.value)} fullWidth />
            <TextField select label="Role" value={form.role} onChange={e => set('role', e.target.value)} fullWidth>
              <MenuItem value="CUSTOMER">CUSTOMER</MenuItem>
              <MenuItem value="ADMIN">ADMIN</MenuItem>
              <MenuItem value="BRANCH_MANAGER">BRANCH_MANAGER</MenuItem>
              <MenuItem value="DELIVERY_PARTNER">DELIVERY_PARTNER</MenuItem>
            </TextField>
          </Stack>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setOpen(false)}>Cancel</Button>
          <Button variant="contained" onClick={() => createM.mutate(form)} disabled={createM.isPending}>Create</Button>
        </DialogActions>
      </Dialog>

      <Snackbar open={!!snack} autoHideDuration={3000} onClose={() => setSnack('')} message={snack} anchorOrigin={{ vertical: 'bottom', horizontal: 'right' }} />
    </Box>
  );
}
