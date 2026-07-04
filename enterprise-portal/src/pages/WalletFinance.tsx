// @ts-nocheck
import React, { useState } from 'react';
import {
  Box, Card, CardContent, Typography, Grid, Button, Table, TableBody,
  TableCell, TableContainer, TableHead, TableRow, TextField, Alert, MenuItem
} from '@mui/material';
import { AccountBalance, CreditCard, Save } from '@mui/icons-material';

interface Transaction {
  id: string;
  email: string;
  type: 'CREDIT' | 'DEBIT';
  amount: number;
  description: string;
  timestamp: string;
}

export default function WalletFinance() {
  const [balance, setBalance] = useState(50.00);
  const [email, setEmail] = useState('');
  const [amount, setAmount] = useState('');
  const [type, setType] = useState<'CREDIT' | 'DEBIT'>('CREDIT');
  const [desc, setDesc] = useState('');
  const [txs, setTxs] = useState<Transaction[]>([
    { id: 'tx-001', email: 'super_admin@hyperlocal.app', type: 'CREDIT', amount: 50.00, description: 'Initial test wallet credit', timestamp: '2026-07-03 10:35 AM' }
  ]);

  const handleAdjustWallet = () => {
    if (!email || !amount) return;
    const value = parseFloat(amount) || 0;
    if (value <= 0) return;

    if (type === 'CREDIT') {
      setBalance(balance + value);
    } else {
      setBalance(Math.max(0, balance - value));
    }

    const newTx: Transaction = {
      id: 'tx-' + Math.random().toString(36).substr(2, 6),
      email,
      type,
      amount: value,
      description: desc || 'Manual adjustment',
      timestamp: new Date().toLocaleString()
    };

    setTxs([newTx, ...txs]);
    setAmount('');
    setDesc('');
  };

  return (
    <Box>
      <Typography variant="h4" fontWeight="bold" gutterBottom mb={4}>
        Platform Treasury & Ledger
      </Typography>

      <Grid container spacing={3}>
        <Grid item xs={12} md={4}>
          <Card sx={{ mb: 3 }}>
            <CardContent>
              <Typography variant="body2" color="text.secondary" gutterBottom>
                Super Admin Test Balance
              </Typography>
              <Typography variant="h3" fontWeight="bold" color="secondary">
                ${balance.toFixed(2)}
              </Typography>
            </CardContent>
          </Card>

          <Card>
            <CardContent sx={{ display: 'flex', flexDirection: 'column', gap: 2.5 }}>
              <Typography variant="h6" fontWeight="bold">
                Adjust Wallet Balance
              </Typography>
              <TextField
                fullWidth
                label="Target User Email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
              />
              <TextField
                fullWidth
                select
                label="Adjustment Type"
                value={type}
                onChange={(e) => setType(e.target.value as any)}
              >
                <MenuItem value="CREDIT">Credit Balance (+)</MenuItem>
                <MenuItem value="DEBIT">Debit Balance (-)</MenuItem>
              </TextField>
              <TextField
                fullWidth
                label="Amount ($)"
                type="number"
                value={amount}
                onChange={(e) => setAmount(e.target.value)}
              />
              <TextField
                fullWidth
                label="Reference / Reason"
                value={desc}
                onChange={(e) => setDesc(e.target.value)}
              />
              <Button
                variant="contained"
                color="primary"
                startIcon={<Save />}
                onClick={handleAdjustWallet}
                disabled={!email || !amount}
              >
                Execute Transaction
              </Button>
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} md={8}>
          <Card sx={{ minHeight: 450 }}>
            <CardContent>
              <Typography variant="h6" fontWeight="bold" gutterBottom>
                Wallet Audit Transactions Log
              </Typography>
              <Typography variant="body2" color="text.secondary" mb={3}>
                All financial movements generate immutable transactional audit payloads.
              </Typography>
              <TableContainer>
                <Table>
                  <TableHead>
                    <TableRow>
                      <TableCell>Tx ID</TableCell>
                      <TableCell>Account Email</TableCell>
                      <TableCell>Type</TableCell>
                      <TableCell>Amount</TableCell>
                      <TableCell>Description</TableCell>
                      <TableCell>Timestamp</TableCell>
                    </TableRow>
                  </TableHead>
                  <TableBody>
                    {txs.map((tx) => (
                      <TableRow key={tx.id}>
                        <TableCell fontWeight="bold">{tx.id}</TableCell>
                        <TableCell>{tx.email}</TableCell>
                        <TableCell>
                          <Alert
                            severity={tx.type === 'CREDIT' ? 'success' : 'error'}
                            icon={false}
                            sx={{ py: 0, px: 1, display: 'inline-flex' }}
                          >
                            {tx.type}
                          </Alert>
                        </TableCell>
                        <TableCell fontWeight="bold">${tx.amount.toFixed(2)}</TableCell>
                        <TableCell>{tx.description}</TableCell>
                        <TableCell>{tx.timestamp}</TableCell>
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
