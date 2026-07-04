// @ts-nocheck
import React, { useState } from 'react';
import { useAuth } from './useAuth';
import { useNavigate } from 'react-router-dom';
import {
  Box, Card, CardContent, TextField, Button, Typography, Tabs, Tab,
  Alert, InputAdornment, IconButton, CircularProgress, Dialog, DialogTitle,
  DialogContent, DialogActions, DialogContentText
} from '@mui/material';
import {
  Email as EmailIcon, Lock as LockIcon, Send as SendIcon,
  Visibility as VisibilityIcon, VisibilityOff as VisibilityOffIcon,
  Google as GoogleIcon, Security as SecurityIcon
} from '@mui/icons-material';

export function LoginPage() {
  const { login, loginWithGoogle } = useAuth();
  const navigate = useNavigate();

  const [tabIndex, setTabIndex] = useState(0); // 0: Password, 1: Google
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // IAM state machines
  const [authState, setAuthState] = useState<'credentials' | 'otp' | 'force_reset'>('credentials');
  const [otpCode, setOtpCode] = useState('');
  const [conflictOpen, setConflictOpen] = useState(false);
  const [newPassword, setNewPassword] = useState('');

  const handleTabChange = (_: any, newValue: number) => {
    setTabIndex(newValue);
    setError(null);
    setAuthState('credentials');
  };

  const handleLoginSubmit = async (e: React.FormEvent, isTakeover = false) => {
    e.preventDefault();
    if (!email) return;

    setLoading(true);
    setError(null);

    try {
      if (authState === 'credentials') {
        const data = await login(email, password, 'password', isTakeover);
        if (data) {
          if (data.authenticationState === 'OTP_REQUIRED') {
            setAuthState('otp');
          } else if (data.authenticationState === 'SESSION_CONFLICT') {
            setConflictOpen(true);
          } else if (data.authenticationState === 'PASSWORD_CHANGE_REQUIRED') {
            setAuthState('force_reset');
          } else if (data.authenticationState === 'LOGIN_COMPLETED') {
            navigate('/');
          }
        }
      } else if (authState === 'otp') {
        const data = await login(email, otpCode, 'otp', isTakeover);
        if (data) {
          if (data.authenticationState === 'SESSION_CONFLICT') {
            setConflictOpen(true);
          } else if (data.authenticationState === 'LOGIN_COMPLETED') {
            navigate('/');
          } else {
            setError('Invalid verification code.');
          }
        }
      }
    } catch (err: any) {
      setError(err.response?.data?.message || err.message || 'Authentication failed');
    } finally {
      setLoading(false);
    }
  };

  const handleTakeover = async () => {
    setConflictOpen(false);
    if (authState === 'otp') {
      await handleLoginSubmit({ preventDefault: () => {} } as any, true);
    } else {
      await handleLoginSubmit({ preventDefault: () => {} } as any, true);
    }
  };

  const handleForceResetSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newPassword || newPassword.length < 12) {
      setError('Password must be at least 12 characters and meet policy requirements.');
      return;
    }
    setLoading(true);
    setError(null);
    try {
      // Complete password reset and log in
      const res = await fetch('/api/v1/auth/reset-password', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email, otpCode: 'ROOT_INITIAL_OTP', newPassword })
      });
      if (res.ok) {
        setAuthState('credentials');
        setPassword(newPassword);
        setError('Password updated. Please log in with your new password.');
      } else {
        const parsed = await res.json();
        setError(parsed.message || 'Failed to update credentials.');
      }
    } catch (err: any) {
      setError(err.message || 'Network failure.');
    } finally {
      setLoading(false);
    }
  };

  const handleMockGoogleLogin = async () => {
    setLoading(true);
    setError(null);
    try {
      const mockIdToken = "mock_google_id_token_" + btoa(email || "customer@hyperlocal.app");
      await loginWithGoogle(mockIdToken);
      navigate('/');
    } catch (err: any) {
      setError(err.response?.data?.message || err.message || 'Google Login failed');
    } finally {
      setLoading(false);
    }
  };

  return (
    <Box
      display="flex"
      justifyContent="center"
      alignItems="center"
      minHeight="100vh"
      sx={{
        backgroundColor: '#121212',
        background: 'radial-gradient(circle at center, #1b1625 0%, #121212 100%)',
      }}
    >
      <Card sx={{ maxWidth: 450, width: '100%', mx: 2, p: 2 }}>
        <CardContent>
          <Box display="flex" flexDirection="column" alignItems="center" mb={3}>
            <Typography variant="h4" fontWeight="bold" color="primary" gutterBottom>
              HyperLocal
            </Typography>
            <Typography variant="body2" color="text.secondary">
              Zero Trust Control Console
            </Typography>
          </Box>

          <Tabs value={tabIndex} onChange={handleTabChange} variant="fullWidth" sx={{ mb: 3 }}>
            <Tab label="Staff Identity" disabled={authState !== 'credentials'} />
            <Tab label="Google Account" disabled={authState !== 'credentials'} />
          </Tabs>

          {error && <Alert severity="error" sx={{ mb: 2 }}>{error}</Alert>}

          {tabIndex === 0 && authState === 'credentials' && (
            <form onSubmit={(e) => handleLoginSubmit(e)}>
              <TextField
                fullWidth
                label="Email Address"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                sx={{ mb: 2 }}
                InputProps={{
                  startAdornment: (
                    <InputAdornment position="start">
                      <EmailIcon color="action" />
                    </InputAdornment>
                  ),
                }}
              />
              <TextField
                fullWidth
                type={showPassword ? 'text' : 'password'}
                label="Password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                sx={{ mb: 3 }}
                InputProps={{
                  startAdornment: (
                    <InputAdornment position="start">
                      <LockIcon color="action" />
                    </InputAdornment>
                  ),
                  endAdornment: (
                    <InputAdornment position="end">
                      <IconButton onClick={() => setShowPassword(!showPassword)} edge="end">
                        {showPassword ? <VisibilityOffIcon /> : <VisibilityIcon />}
                      </IconButton>
                    </InputAdornment>
                  ),
                }}
              />
              <Button
                fullWidth
                type="submit"
                variant="contained"
                color="primary"
                disabled={loading || !email || !password}
                size="large"
              >
                {loading ? <CircularProgress size={24} /> : 'Authenticate Credentials'}
              </Button>
            </form>
          )}

          {tabIndex === 0 && authState === 'otp' && (
            <form onSubmit={(e) => handleLoginSubmit(e)}>
              <Typography variant="body2" color="text.secondary" mb={2} align="center">
                Multi-Factor Authentication Required. Enter the 6-digit OTP code sent to your email registry.
              </Typography>
              <TextField
                fullWidth
                label="MFA Security OTP"
                value={otpCode}
                onChange={(e) => setOtpCode(e.target.value)}
                sx={{ mb: 3 }}
                InputProps={{
                  startAdornment: (
                    <InputAdornment position="start">
                      <SecurityIcon color="action" />
                    </InputAdornment>
                  ),
                }}
              />
              <Button
                fullWidth
                type="submit"
                variant="contained"
                color="primary"
                disabled={loading || !otpCode}
                size="large"
              >
                {loading ? <CircularProgress size={24} /> : 'Verify Code & Sign In'}
              </Button>
            </form>
          )}

          {tabIndex === 0 && authState === 'force_reset' && (
            <form onSubmit={handleForceResetSubmit}>
              <Typography variant="body2" color="warning.main" mb={2} align="center">
                Credential Reset Required. Setup a secure, 12+ character administrator password.
              </Typography>
              <TextField
                fullWidth
                type="password"
                label="New Secure Password"
                value={newPassword}
                onChange={(e) => setNewPassword(e.target.value)}
                sx={{ mb: 3 }}
              />
              <Button
                fullWidth
                type="submit"
                variant="contained"
                color="warning"
                disabled={loading || !newPassword}
                size="large"
              >
                Setup Password & Activate
              </Button>
            </form>
          )}

          {tabIndex === 1 && (
            <Box display="flex" flexDirection="column" gap={2}>
              <Typography variant="body2" color="text.secondary" align="center" mb={2}>
                Customer Identity Access Node
              </Typography>
              <TextField
                fullWidth
                label="Customer Email Address"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                sx={{ mb: 1 }}
              />
              <Button
                fullWidth
                variant="outlined"
                color="secondary"
                startIcon={<GoogleIcon />}
                onClick={handleMockGoogleLogin}
                disabled={loading}
                size="large"
              >
                Continue with Google
              </Button>
            </Box>
          )}
        </CardContent>
      </Card>

      {/* Session Conflict Modal */}
      <Dialog open={conflictOpen} onClose={() => setConflictOpen(false)}>
        <DialogTitle>Concurrent Active Session Detected</DialogTitle>
        <DialogContent>
          <DialogContentText>
            Your account is already active elsewhere. Enforcing the Zero Trust single session policy requires terminating the active session. Would you like to takeover the session?
          </DialogContentText>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setConflictOpen(false)}>Cancel Login</Button>
          <Button variant="contained" color="error" onClick={handleTakeover}>
            Take Over Session
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
}
