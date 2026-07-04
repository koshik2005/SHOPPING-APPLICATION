// @ts-nocheck
import React, { ReactNode } from 'react';
import { useAuth } from '../auth/useAuth';
import { Alert } from '@mui/material';

interface PermissionGuardProps {
  require: string;
  fallback?: ReactNode;
  children: ReactNode;
}

export function PermissionGuard({ require, fallback, children }: PermissionGuardProps) {
  const { can } = useAuth();

  if (!can(require)) {
    if (fallback !== undefined) {
      return <>{fallback}</>;
    }
    return (
      <Alert severity="error" sx={{ my: 2 }}>
        You do not have permission to view or access this element ({require}).
      </Alert>
    );
  }

  return <>{children}</>;
}
