// @ts-nocheck
import React from 'react';
import { Navigate } from 'react-router-dom';
import { useAuth } from './useAuth';
import { CircularProgress, Box, Typography, Button } from '@mui/material';

interface ProtectedRouteProps {
  children: React.ReactNode;
  requirePermission?: string;
  requireRoles?: string[];
}

export function ProtectedRoute({ children, requirePermission, requireRoles }: ProtectedRouteProps) {
  const { isAuthenticated, isLoading, can, hasRole, logout } = useAuth();

  if (isLoading) {
    return (
      <Box display="flex" justifyContent="center" alignItems="center" minHeight="100vh">
        <CircularProgress color="primary" />
      </Box>
    );
  }

  if (!isAuthenticated) {
    return <Navigate to="/login" replace />;
  }

  if (requirePermission && !can(requirePermission)) {
    return <AccessDeniedScreen onLogout={logout} />;
  }

  if (requireRoles && !hasRole(requireRoles)) {
    return <AccessDeniedScreen onLogout={logout} />;
  }

  return <>{children}</>;
}

function AccessDeniedScreen({ onLogout }: { onLogout: () => void }) {
  return (
    <Box display="flex" flexDirection="column" justifyContent="center" alignItems="center" minHeight="100vh" gap={2}>
      <Typography variant="h4" color="error" fontWeight="bold">
        Access Denied
      </Typography>
      <Typography variant="body1" color="text.secondary">
        You do not have the required permissions to access this page.
      </Typography>
      <Button variant="contained" color="primary" onClick={onLogout} sx={{ mt: 2 }}>
        Sign Out & Try Again
      </Button>
    </Box>
  );
}
