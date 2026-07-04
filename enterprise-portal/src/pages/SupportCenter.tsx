// @ts-nocheck
import React, { useState } from 'react';
import {
  Box, Card, CardContent, Typography, Grid, Button, Table, TableBody,
  TableCell, TableContainer, TableHead, TableRow, Chip, TextField, Dialog,
  DialogTitle, DialogContent, DialogActions
} from '@mui/material';
import { SupportAgent, Help, Chat } from '@mui/icons-material';

interface Ticket {
  id: string;
  customer: string;
  subject: string;
  status: 'OPEN' | 'RESOLVED' | 'ESCALATED';
  priority: 'LOW' | 'MEDIUM' | 'HIGH';
  createdAt: string;
}

export default function SupportCenter() {
  const [tickets, setTickets] = useState<Ticket[]>([
    { id: 'TKT-101', customer: 'customer_1@hyperlocal.app', subject: 'Refund request for delayed order #551', status: 'OPEN', priority: 'HIGH', createdAt: '2026-07-03 10:10 AM' },
    { id: 'TKT-102', customer: 'customer_2@hyperlocal.app', subject: 'Cannot load checkout payment options', status: 'ESCALATED', priority: 'MEDIUM', createdAt: '2026-07-03 09:30 AM' },
    { id: 'TKT-103', customer: 'customer_3@hyperlocal.app', subject: 'Feedback on rider behavior', status: 'RESOLVED', priority: 'LOW', createdAt: '2026-07-02 04:15 PM' }
  ]);

  const [activeTicket, setActiveTicket] = useState<Ticket | null>(null);
  const [openChat, setOpenChat] = useState(false);
  const [message, setMessage] = useState('');
  const [chatLog, setChatLog] = useState<string[]>([
    'Customer: Hello, I have not received my refund for delayed order #551 yet.',
    'System: Assigned to support representative.'
  ]);

  const handleResolve = (id: string) => {
    setTickets(tickets.map(t => t.id === id ? { ...t, status: 'RESOLVED' } : t));
    setOpenChat(false);
  };

  const handleSendMessage = () => {
    if (!message) return;
    setChatLog([...chatLog, `Agent: ${message}`]);
    setMessage('');
  };

  return (
    <Box>
      <Typography variant="h4" fontWeight="bold" gutterBottom mb={4}>
        Resolution Center & Disputes
      </Typography>

      <Grid container spacing={3}>
        <Grid item xs={12} md={8}>
          <Card>
            <CardContent>
              <Typography variant="h6" fontWeight="bold" gutterBottom>
                Active Support Tickets
              </Typography>
              <TableContainer>
                <Table>
                  <TableHead>
                    <TableRow>
                      <TableCell>Ticket ID</TableCell>
                      <TableCell>Customer Account</TableCell>
                      <TableCell>Dispute Subject</TableCell>
                      <TableCell>Priority</TableCell>
                      <TableCell>Status</TableCell>
                      <TableCell align="right">Actions</TableCell>
                    </TableRow>
                  </TableHead>
                  <TableBody>
                    {tickets.map((t) => (
                      <TableRow key={t.id}>
                        <TableCell fontWeight="bold">{t.id}</TableCell>
                        <TableCell>{t.customer}</TableCell>
                        <TableCell>{t.subject}</TableCell>
                        <TableCell>
                          <Chip
                            label={t.priority}
                            size="small"
                            color={t.priority === 'HIGH' ? 'error' : t.priority === 'MEDIUM' ? 'warning' : 'default'}
                          />
                        </TableCell>
                        <TableCell>
                          <Chip
                            label={t.status}
                            size="small"
                            color={t.status === 'OPEN' ? 'primary' : t.status === 'RESOLVED' ? 'success' : 'warning'}
                          />
                        </TableCell>
                        <TableCell align="right">
                          <Button
                            variant="outlined"
                            size="small"
                            startIcon={<Chat />}
                            onClick={() => {
                              setActiveTicket(t);
                              setOpenChat(true);
                            }}
                          >
                            Resolve / Chat
                          </Button>
                        </TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              </TableContainer>
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} md={4}>
          <Card>
            <CardContent sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
              <Typography variant="h6" fontWeight="bold">
                Escalation Protocols
              </Typography>
              <Typography variant="body2" color="text.secondary">
                Verify merchant disputes and escalate delivery partner wallet issues directly to supervisors.
              </Typography>
              <Box display="flex" flexDirection="column" gap={1.5} mt={2}>
                <Typography variant="body2" fontWeight="bold">Standard Guidelines:</Typography>
                <Typography variant="caption">• Delivery delays: refunds automatically credited if delay &gt; 45 mins.</Typography>
                <Typography variant="caption">• Merchant cancellations: chargeback penalty of 10% applied automatically.</Typography>
              </Box>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {/* Resolve / Chat Dialog */}
      {activeTicket && (
        <Dialog open={openChat} onClose={() => setOpenChat(false)} fullWidth maxWidth="sm">
          <DialogTitle>Dispute Resolution — {activeTicket.id}</DialogTitle>
          <DialogContent sx={{ display: 'flex', flexDirection: 'column', gap: 2, pt: 2 }}>
            <Typography variant="body2" fontWeight="bold">
              Subject: {activeTicket.subject}
            </Typography>
            <Box
              sx={{
                height: 250,
                backgroundColor: '#121212',
                border: '1px solid #2c2c2c',
                borderRadius: 2,
                p: 2,
                overflowY: 'auto',
                display: 'flex',
                flexDirection: 'column',
                gap: 1
              }}
            >
              {chatLog.map((log, i) => (
                <Typography key={i} variant="caption" display="block">
                  {log}
                </Typography>
              ))}
            </Box>
            <TextField
              fullWidth
              placeholder="Type message to customer..."
              value={message}
              onChange={(e) => setMessage(e.target.value)}
              onKeyDown={(e) => {
                if (e.key === 'Enter') handleSendMessage();
              }}
            />
          </DialogContent>
          <DialogActions>
            <Button onClick={() => setOpenChat(false)}>Close</Button>
            <Button variant="contained" color="success" onClick={() => handleResolve(activeTicket.id)}>
              Mark as Resolved
            </Button>
            <Button variant="contained" color="primary" onClick={handleSendMessage}>
              Send
            </Button>
          </DialogActions>
        </Dialog>
      )}
    </Box>
  );
}
