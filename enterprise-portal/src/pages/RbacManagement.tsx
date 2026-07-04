// @ts-nocheck
import React, { useState } from 'react';
import {
  Box, Card, CardContent, Typography, Grid, Button, Table, TableBody,
  TableCell, TableContainer, TableHead, TableRow, Checkbox, TextField,
  MenuItem, Alert
} from '@mui/material';
import { Save, FileDownload, Shield } from '@mui/icons-material';

export default function RbacManagement() {
  const [selectedRole, setSelectedRole] = useState('ROLE_BRANCH_MANAGER');

  const [permissions, setPermissions] = useState<Record<string, Record<string, boolean>>>({
    ROLE_BRANCH_MANAGER: {
      'branches:view': true, 'branches:write': true,
      'shops:view': true, 'shops:write': true,
      'products:view': true, 'products:write': true,
      'orders:view': true, 'orders:write': true,
      'wallet:view': false, 'audit-logs:view': false,
    },
    ROLE_SHOP_OWNER: {
      'branches:view': false, 'branches:write': false,
      'shops:view': true, 'shops:write': false,
      'products:view': true, 'products:write': true,
      'orders:view': true, 'orders:write': true,
      'wallet:view': false, 'audit-logs:view': false,
    },
    ROLE_QA_ENGINEER: {
      'branches:view': true, 'branches:write': false,
      'shops:view': true, 'shops:write': false,
      'products:view': true, 'products:write': false,
      'orders:view': true, 'orders:write': true,
      'wallet:view': true, 'audit-logs:view': true,
    }
  });

  const handleToggle = (role: string, perm: string) => {
    setPermissions({
      ...permissions,
      [role]: {
        ...permissions[role],
        [perm]: !permissions[role][perm]
      }
    });
  };

  const exportMatrix = () => {
    const csvContent = "data:text/csv;charset=utf-8,Role,Permission,Granted\n"
      + Object.entries(permissions).flatMap(([r, perms]) =>
          Object.entries(perms).map(([p, val]) => `${r},${p},${val}`)
        ).join("\n");
    
    const encodedUri = encodeURI(csvContent);
    const link = document.createElement("a");
    link.setAttribute("href", encodedUri);
    link.setAttribute("download", "rbac_matrix.csv");
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  };

  const currentRolePerms = permissions[selectedRole] || {};

  return (
    <Box>
      <Box display="flex" justifyContent="space-between" alignItems="center" mb={4}>
        <Typography variant="h4" fontWeight="bold">
          Access Control Configuration
        </Typography>
        <Button
          variant="outlined"
          color="secondary"
          startIcon={<FileDownload />}
          onClick={exportMatrix}
        >
          Export Matrix (CSV)
        </Button>
      </Box>

      <Grid container spacing={3}>
        <Grid item xs={12} md={4}>
          <Card>
            <CardContent sx={{ display: 'flex', flexDirection: 'column', gap: 3 }}>
              <Typography variant="h6" fontWeight="bold">
                Role Templates
              </Typography>
              <TextField
                select
                fullWidth
                label="Select Role Profile"
                value={selectedRole}
                onChange={(e) => setSelectedRole(e.target.value)}
              >
                <MenuItem value="ROLE_BRANCH_MANAGER">Branch Manager</MenuItem>
                <MenuItem value="ROLE_SHOP_OWNER">Shop Owner</MenuItem>
                <MenuItem value="ROLE_QA_ENGINEER">QA Engineer</MenuItem>
              </TextField>

              <Alert severity="info">
                Modifications update the local template configuration. In production, this pushes schema records directly into the `user_roles` database repository.
              </Alert>

              <Button
                variant="contained"
                color="primary"
                startIcon={<Save />}
                fullWidth
              >
                Save Role Template
              </Button>
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} md={8}>
          <Card>
            <CardContent>
              <Typography variant="h6" fontWeight="bold" gutterBottom>
                Scope & Action Permissions
              </Typography>
              <TableContainer>
                <Table>
                  <TableHead>
                    <TableRow>
                      <TableCell>System Permission Key</TableCell>
                      <TableCell align="center">Access Granted</TableCell>
                    </TableRow>
                  </TableHead>
                  <TableBody>
                    {Object.entries(currentRolePerms).map(([perm, val]) => (
                      <TableRow key={perm}>
                        <TableCell fontWeight="500">{perm}</TableCell>
                        <TableCell align="center">
                          <Checkbox
                            checked={val}
                            onChange={() => handleToggle(selectedRole, perm)}
                            color="primary"
                          />
                        </TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              </TableContainer>
            </CardContent>
          </Card>
        </Grid>
      </Grid>
    </Box>
  );
}
