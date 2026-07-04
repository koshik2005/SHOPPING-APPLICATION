// @ts-nocheck
import React, { useState } from 'react';
import {
  Box, Card, CardContent, Typography, Grid, Button, Table, TableBody,
  TableCell, TableContainer, TableHead, TableRow, Chip, IconButton, Dialog,
  DialogTitle, DialogContent, DialogActions, TextField, MenuItem, Tabs, Tab
} from '@mui/material';
import {
  Block, CheckCircle, Delete, Edit, Key, PowerSettingsNew,
  Visibility, PersonAdd, Security, Devices
} from '@mui/icons-material';

interface UserProfile {
  id: string;
  email: string;
  roles: string[];
  status: 'ACTIVE' | 'SUSPENDED' | 'DELETED';
  lastLogin: string;
  device: string;
}

export default function UserManagement() {
  const [tab, setTab] = useState(0);
  const [users, setUsers] = useState<UserProfile[]>([
    { id: '1', email: 'super_admin@hyperlocal.app', roles: ['ROLE_SUPER_ADMIN'], status: 'ACTIVE', lastLogin: '2026-07-03 10:45 AM', device: 'Chrome / macOS' },
    { id: '2', email: 'branch_manager_1@hyperlocal.app', roles: ['ROLE_BRANCH_MANAGER'], status: 'ACTIVE', lastLogin: '2026-07-03 09:12 AM', device: 'Safari / iPhone' },
    { id: '3', email: 'merchant_owner@hyperlocal.app', roles: ['ROLE_SHOP_OWNER'], status: 'ACTIVE', lastLogin: '2026-07-02 04:30 PM', device: 'Chrome / Windows' },
    { id: '4', email: 'delivery_rider_101@hyperlocal.app', roles: ['ROLE_DELIVERY_PARTNER'], status: 'ACTIVE', lastLogin: '2026-07-03 11:05 AM', device: 'DeliveryApp / Android' },
    { id: '5', email: 'support_agent_2@hyperlocal.app', roles: ['ROLE_SUPPORT_AGENT'], status: 'SUSPENDED', lastLogin: '2026-06-30 02:15 PM', device: 'Firefox / Ubuntu' }
  ]);

  const [openAdd, setOpenAdd] = useState(false);
  const [email, setEmail] = useState('');
  const [role, setRole] = useState('ROLE_BRANCH_MANAGER');

  const handleStatusToggle = (id: string) => {
    setUsers(users.map(u => {
      if (u.id === id) {
        return { ...u, status: u.status === 'ACTIVE' ? 'SUSPENDED' : 'ACTIVE' };
      }
      return u;
    }));
  };

  const handleAddUser = () => {
    if (!email) return;
    const newUser: UserProfile = {
      id: (users.length + 1).toString(),
      email,
      roles: [role],
      status: 'ACTIVE',
      lastLogin: 'Never',
      device: 'Unknown'
    };
    setUsers([...users, newUser]);
    setEmail('');
    setOpenAdd(false);
  };

  return (
    <Box>
      <Box display="flex" justifyContent="space-between" alignItems="center" mb={4}>
        <Typography variant="h4" fontWeight="bold">
          Account Registry
        </Typography>
        <Button
          variant="contained"
          color="primary"
          startIcon={<PersonAdd />}
          onClick={() => setOpenAdd(true)}
        >
          Create User Account
        </Button>
      </Box>

      <Tabs value={tab} onChange={(_, v) => setTab(v)} sx={{ mb: 3 }}>
        <Tab label="Administrative staff" />
        <Tab label="Delivery Partners" />
        <Tab label="End Customers" />
        <Tab label="Session registry" />
      </Tabs>

      {tab !== 3 ? (
        <Card>
          <TableContainer>
            <Table>
              <TableHead>
                <TableRow>
                  <TableCell>Email / Account</TableCell>
                  <TableCell>Assigned Roles</TableCell>
                  <TableCell>Status</TableCell>
                  <TableCell>Last Activity</TableCell>
                  <TableCell>Binding Device</TableCell>
                  <TableCell align="right">Actions</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {users.filter(u => {
                  if (tab === 0) return !u.roles.includes('ROLE_DELIVERY_PARTNER') && !u.roles.includes('ROLE_CUSTOMER');
                  if (tab === 1) return u.roles.includes('ROLE_DELIVERY_PARTNER');
                  return u.roles.includes('ROLE_CUSTOMER');
                }).map((user) => (
                  <TableRow key={user.id}>
                    <TableCell fontWeight="bold">{user.email}</TableCell>
                    <TableCell>
                      {user.roles.map(r => (
                        <Chip key={r} label={r.replace('ROLE_', '')} size="small" color="secondary" sx={{ mr: 0.5 }} />
                      ))}
                    </TableCell>
                    <TableCell>
                      <Chip
                        label={user.status}
                        size="small"
                        color={user.status === 'ACTIVE' ? 'success' : 'error'}
                      />
                    </TableCell>
                    <TableCell>{user.lastLogin}</TableCell>
                    <TableCell>{user.device}</TableCell>
                    <TableCell align="right">
                      <IconButton onClick={() => handleStatusToggle(user.id)}>
                        {user.status === 'ACTIVE' ? <Block color="warning" /> : <CheckCircle color="success" />}
                      </IconButton>
                      <IconButton color="error">
                        <Delete />
                      </IconButton>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </TableContainer>
        </Card>
      ) : (
        <Grid container spacing={3}>
          <Grid item xs={12} md={8}>
            <Card>
              <CardContent>
                <Typography variant="h6" fontWeight="bold" gutterBottom>
                  Active JWT Signatures
                </Typography>
                <Typography variant="body2" color="text.secondary" mb={3}>
                  Terminating a session deletes the token hash from the Redis cache, triggering immediate logout.
                </Typography>
                <Table>
                  <TableHead>
                    <TableRow>
                      <TableCell>Session ID</TableCell>
                      <TableCell>User</TableCell>
                      <TableCell>IP Address</TableCell>
                      <TableCell>Expires At</TableCell>
                      <TableCell align="right">Revocation</TableCell>
                    </TableRow>
                  </TableHead>
                  <TableBody>
                    <TableRow>
                      <TableCell>sess-8f3b2072</TableCell>
                      <TableCell>super_admin@hyperlocal.app</TableCell>
                      <TableCell>192.168.1.45</TableCell>
                      <TableCell>In 7 days</TableCell>
                      <TableCell align="right">
                        <Button color="error" size="small" startIcon={<PowerSettingsNew />}>
                          Force Kill
                        </Button>
                      </TableCell>
                    </TableRow>
                  </TableBody>
                </Table>
              </CardContent>
            </Card>
          </Grid>
          <Grid item xs={12} md={4}>
            <Card>
              <CardContent>
                <Typography variant="h6" fontWeight="bold" gutterBottom>
                  Remote System Signout
                </Typography>
                <Typography variant="body2" color="text.secondary" mb={3}>
                  Invalidate all active sessions across all devices for the specified account email.
                </Typography>
                <TextField fullWidth label="Account Email" placeholder="user@hyperlocal.app" sx={{ mb: 2 }} />
                <Button fullWidth variant="contained" color="error" startIcon={<PowerSettingsNew />}>
                  Revoke All Tokens
                </Button>
              </CardContent>
            </Card>
          </Grid>
        </Grid>
      )}

      {/* Create User Dialog */}
      <Dialog open={openAdd} onClose={() => setOpenAdd(false)}>
        <DialogTitle>Provision Account</DialogTitle>
        <DialogContent sx={{ minWidth: 350, display: 'flex', flexDirection: 'column', gap: 2, pt: 1 }}>
          <TextField
            fullWidth
            label="Email Address"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
          />
          <TextField
            fullWidth
            select
            label="Default Role Template"
            value={role}
            onChange={(e) => setRole(e.target.value)}
          >
            <MenuItem value="ROLE_BRANCH_MANAGER">Branch Manager</MenuItem>
            <MenuItem value="ROLE_SHOP_OWNER">Shop Owner</MenuItem>
            <MenuItem value="ROLE_SUPPORT_AGENT">Support Agent</MenuItem>
            <MenuItem value="ROLE_FINANCE">Finance Auditor</MenuItem>
            <MenuItem value="ROLE_QA_ENGINEER">QA Engineer</MenuItem>
          </TextField>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setOpenAdd(false)}>Cancel</Button>
          <Button variant="contained" onClick={handleAddUser}>Provision</Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
}
