// @ts-nocheck
import React, { createContext, useState, useEffect, ReactNode } from 'react';
import client from '../api/client';

export interface User {
  id: string;
  email: string;
  role: string; // Legacy/Primary role
  roles: string[]; // List of all roles
  branchId?: string;
  shopId?: string;
  profile?: {
    displayName: string;
    profilePhotoUrl: string;
  };
}

interface AuthContextType {
  user: User | null;
  isAuthenticated: boolean;
  isLoading: boolean;
  login: (email: string, passOrOtp: string, method: 'password' | 'otp') => Promise<any>;
  loginWithGoogle: (idToken: string) => Promise<any>;
  logout: () => Promise<void>;
  hasRole: (roles: string[]) => boolean;
  can: (permission: string) => boolean;
}

export const AuthContext = createContext<AuthContextType | undefined>(undefined);

// Define UI Permission Matrix matching backend
const ROLE_PERMISSIONS: Record<string, string[]> = {
  ROLE_SUPER_ADMIN: ['*'],
  ROLE_SYSTEM_ADMIN: [
    'dashboard:view', 'branches:view', 'branches:write', 'shops:view', 'shops:write',
    'products:view', 'products:write', 'categories:view', 'categories:write', 'orders:view',
    'orders:write', 'customers:view', 'customers:write', 'delivery:view', 'inventory:view',
    'payments:view', 'wallet:view', 'reports:view', 'analytics:view', 'notifications:view',
    'users:view', 'users:write', 'audit-logs:view', 'system-settings:view', 'system-settings:write'
  ],
  ROLE_BRANCH_MANAGER: [
    'dashboard:view', 'branches:view', 'shops:view', 'shops:write', 'products:view',
    'products:write', 'orders:view', 'orders:write', 'delivery:view', 'inventory:view',
    'reports:view', 'analytics:view', 'notifications:view'
  ],
  ROLE_SHOP_OWNER: [
    'dashboard:view', 'shops:view', 'products:view', 'products:write', 'orders:view',
    'orders:write', 'inventory:view', 'reports:view'
  ],
  ROLE_SHOP_MANAGER: [
    'dashboard:view', 'shops:view', 'products:view', 'orders:view', 'orders:write', 'inventory:view'
  ],
  ROLE_QA_ENGINEER: [
    'dashboard:view', 'branches:view', 'shops:view', 'products:view', 'orders:view',
    'customers:view', 'delivery:view', 'payments:view', 'wallet:view', 'reports:view',
    'audit-logs:view', 'testing-tools:view'
  ],
  ROLE_SUPPORT_AGENT: [
    'dashboard:view', 'branches:view', 'shops:view', 'products:view', 'orders:view',
    'orders:write', 'customers:view', 'customers:write', 'wallet:view', 'payments:view'
  ],
  ROLE_FINANCE: [
    'dashboard:view', 'orders:view', 'payments:view', 'payments:write', 'wallet:view',
    'wallet:write', 'reports:view', 'analytics:view'
  ],
  ROLE_AUDITOR: [
    'dashboard:view', 'branches:view', 'shops:view', 'products:view', 'orders:view',
    'customers:view', 'delivery:view', 'payments:view', 'wallet:view', 'reports:view',
    'audit-logs:view'
  ]
};

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    const storedUser = localStorage.getItem('user');
    const token = localStorage.getItem('accessToken');
    if (storedUser && token) {
      setUser(JSON.parse(storedUser));
    }
    setIsLoading(false);
  }, []);

  const login = async (email: string, passOrOtp: string, method: 'password' | 'otp', takeover = false) => {
    setIsLoading(true);
    try {
      const url = method === 'password' ? '/api/v1/auth/verify-password' : '/api/v1/auth/verify-otp';
      const body = method === 'password' 
        ? { email, password: passOrOtp, takeover }
        : { emailOrPhone: email, otpCode: passOrOtp, takeover };

      const res = await client.post(url, body);
      const authData = res.data?.data;
      if (authData && authData.accessToken && authData.authenticationState === 'LOGIN_COMPLETED') {
        saveSession(authData);
      }
      return authData;
    } finally {
      setIsLoading(false);
    }
  };

  const loginWithGoogle = async (idToken: string) => {
    setIsLoading(true);
    try {
      const res = await client.post('/api/v1/auth/google-login', {
        idToken,
        device: {
          deviceId: 'web_portal_' + Math.abs(window.navigator.userAgent.hashCode()),
          deviceName: 'Browser',
          platform: 'Web',
          osVersion: 'HTML5',
          fcmToken: 'none'
        }
      });
      const authData = res.data?.data;
      if (authData && authData.accessToken) {
        saveSession(authData);
        return authData;
      }
      throw new Error(res.data?.message || 'Google Login failed');
    } finally {
      setIsLoading(false);
    }
  };

  const logout = async () => {
    setIsLoading(true);
    try {
      const sessionId = localStorage.getItem('sessionId');
      if (sessionId) {
        await client.post('/api/v1/auth/logout', null, {
          headers: { 'X-Session-ID': sessionId }
        });
      }
    } catch (e) {
      console.warn("Failed remote logout: ", e);
    } finally {
      localStorage.clear();
      setUser(null);
      setIsLoading(false);
      window.location.href = '/login';
    }
  };

  const saveSession = (authData: any) => {
    localStorage.setItem('accessToken', authData.accessToken);
    localStorage.setItem('refreshToken', authData.refreshToken);
    
    // Parse JWT to extract roles, branchId, shopId
    const base64Url = authData.accessToken.split('.')[1];
    const base64 = base64Url.replace(/-/g, '+').replace(/_/g, '/');
    const claims = JSON.parse(window.atob(base64));

    const userData: User = {
      id: claims.sub,
      email: claims.email,
      role: claims.role,
      roles: claims.roles || [claims.role],
      branchId: claims.branchId,
      shopId: claims.shopId,
      profile: authData.user?.profile
    };

    localStorage.setItem('sessionId', claims.sessionId);
    localStorage.setItem('user', JSON.stringify(userData));
    setUser(userData);
  };

  const hasRole = (roles: string[]) => {
    if (!user) return false;
    return user.roles.some(r => roles.includes(r));
  };

  const can = (permission: string) => {
    if (!user) return false;
    // Super admin matches all permissions
    if (user.roles.includes('ROLE_SUPER_ADMIN')) return true;

    for (const role of user.roles) {
      const perms = ROLE_PERMISSIONS[role];
      if (perms) {
        if (perms.includes('*') || perms.includes(permission)) {
          return true;
        }
      }
    }
    return false;
  };

  return (
    <AuthContext.Provider value={{
      user,
      isAuthenticated: !!user,
      isLoading,
      login,
      loginWithGoogle,
      logout,
      hasRole,
      can
    }}>
      {children}
    </AuthContext.Provider>
  );
}

// polyfill hashCode for UserAgent fingerprinting
if (!String.prototype.hashCode) {
  String.prototype.hashCode = function() {
    let hash = 0;
    for (let i = 0; i < this.length; i++) {
      const char = this.charCodeAt(i);
      hash = ((hash << 5) - hash) + char;
      hash = hash & hash;
    }
    return hash;
  };
}

declare global {
  interface String {
    hashCode(): number;
  }
}
