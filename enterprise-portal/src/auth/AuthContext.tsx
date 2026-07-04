// @ts-nocheck
import React, { createContext, useState, useEffect, useCallback, ReactNode } from 'react';
import client from '../api/client';
import { clearPermissionsCache } from '../hooks/usePermissions';
import { clearNavCache } from '../hooks/useNavigationMenu';

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
  permissions: Set<string>;
  login: (email: string, passOrOtp: string, method: 'password' | 'otp') => Promise<any>;
  loginWithGoogle: (idToken: string) => Promise<any>;
  logout: () => Promise<void>;
  hasRole: (roles: string[]) => boolean;
  can: (permission: string) => boolean;
}

export const AuthContext = createContext<AuthContextType | undefined>(undefined);

/**
 * DYNAMIC RBAC — permissions are loaded from the backend API.
 * The hardcoded ROLE_PERMISSIONS map has been REMOVED.
 * All permissions now live in the database (role_permission_mappings table)
 * and are fetched from GET /api/v1/auth/rbac/permissions/multi
 */

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  // Dynamic permissions — loaded from backend RBAC API after login
  const [permissions, setPermissions] = useState<Set<string>>(new Set());
  const [permissionsLoaded, setPermissionsLoaded] = useState(false);

  useEffect(() => {
    const storedUser = localStorage.getItem('user');
    const token = localStorage.getItem('accessToken');
    if (storedUser && token) {
      const parsedUser = JSON.parse(storedUser);
      setUser(parsedUser);
      // Restore permissions from cache or re-fetch
      loadPermissionsForUser(parsedUser);
    } else {
      setIsLoading(false);
    }
  }, []);

  const loadPermissionsForUser = useCallback(async (u: User) => {
    if (!u || !u.roles || u.roles.length === 0) {
      setPermissions(new Set());
      setPermissionsLoaded(true);
      setIsLoading(false);
      return;
    }
    if (u.roles.includes('ROLE_SUPER_ADMIN')) {
      setPermissions(new Set(['*']));
      setPermissionsLoaded(true);
      setIsLoading(false);
      return;
    }
    try {
      const res = await client.get('/api/v1/auth/rbac/permissions/multi', {
        params: { roles: u.roles.join(',') },
      });
      const permsArray: string[] = res.data?.data?.permissions || [];
      setPermissions(new Set(permsArray));
    } catch (e) {
      console.warn('[AuthContext] RBAC permission load failed — no permissions granted:', e);
      setPermissions(new Set()); // Fail-secure
    } finally {
      setPermissionsLoaded(true);
      setIsLoading(false);
    }
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
      setPermissions(new Set());
      setPermissionsLoaded(false);
      clearPermissionsCache();  // Clear RBAC cache
      clearNavCache();           // Clear navigation cache
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
    // Load permissions from backend RBAC after successful login
    loadPermissionsForUser(userData);
  };

  const hasRole = (roles: string[]) => {
    if (!user) return false;
    return user.roles.some(r => roles.includes(r));
  };

  const can = useCallback((permission: string): boolean => {
    if (!user) return false;
    // ROLE_SUPER_ADMIN wildcard
    if (user.roles.includes('ROLE_SUPER_ADMIN')) return true;
    // Check backend-loaded permission set (dynamic, from DB)
    if (permissions.has('*')) return true;
    return permissions.has(permission);
  }, [user, permissions]);

  return (
    <AuthContext.Provider value={{
      user,
      isAuthenticated: !!user,
      isLoading: isLoading || (!!user && !permissionsLoaded),
      permissions,
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
