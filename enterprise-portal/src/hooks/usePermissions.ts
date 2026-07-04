// @ts-nocheck
import { useState, useEffect, useCallback } from 'react';
import client from '../api/client';

interface PermissionsState {
  permissions: Set<string>;
  isLoaded: boolean;
  isSuperAdmin: boolean;
}

/**
 * usePermissions — fetches role permissions from the backend RBAC API.
 *
 * Replaces the hardcoded ROLE_PERMISSIONS constant in AuthContext.tsx.
 * The backend returns the authoritative permission list from the database.
 *
 * Cache strategy: permissions are cached in memory for the session duration.
 * Cache is invalidated on logout (when roles change).
 *
 * API: GET /api/v1/auth/rbac/permissions/multi?roles=ROLE_A,ROLE_B
 */

// Module-level cache — survives re-renders but clears on full page refresh
let permissionsCache: Map<string, Set<string>> = new Map();

function getCacheKey(roles: string[]): string {
  return [...roles].sort().join(',');
}

export function usePermissions(roles: string[]) {
  const [state, setState] = useState<PermissionsState>({
    permissions: new Set<string>(),
    isLoaded: false,
    isSuperAdmin: false,
  });

  const fetchPermissions = useCallback(async () => {
    if (!roles || roles.length === 0) {
      setState({ permissions: new Set(), isLoaded: true, isSuperAdmin: false });
      return;
    }

    // ROLE_SUPER_ADMIN shortcut — no API call needed
    if (roles.includes('ROLE_SUPER_ADMIN')) {
      setState({
        permissions: new Set(['*']),
        isLoaded: true,
        isSuperAdmin: true,
      });
      return;
    }

    const cacheKey = getCacheKey(roles);
    if (permissionsCache.has(cacheKey)) {
      const cached = permissionsCache.get(cacheKey)!;
      setState({
        permissions: cached,
        isLoaded: true,
        isSuperAdmin: cached.has('*'),
      });
      return;
    }

    try {
      const res = await client.get('/api/v1/auth/rbac/permissions/multi', {
        params: { roles: roles.join(',') },
      });
      const permsArray: string[] = res.data?.data?.permissions || [];
      const permsSet = new Set<string>(permsArray);
      permissionsCache.set(cacheKey, permsSet);
      setState({
        permissions: permsSet,
        isLoaded: true,
        isSuperAdmin: permsSet.has('*'),
      });
    } catch (error) {
      console.error('[usePermissions] Failed to load permissions:', error);
      // On error: no permissions (fail-secure)
      setState({ permissions: new Set(), isLoaded: true, isSuperAdmin: false });
    }
  }, [roles.join(',')]); // eslint-disable-line react-hooks/exhaustive-deps

  useEffect(() => {
    fetchPermissions();
  }, [fetchPermissions]);

  /**
   * Check if the current user has a specific permission.
   * ROLE_SUPER_ADMIN always returns true.
   */
  const can = useCallback((permission: string): boolean => {
    if (state.isSuperAdmin) return true;
    return state.permissions.has(permission);
  }, [state]);

  /**
   * Checks if user has all listed permissions (AND logic).
   */
  const canAll = useCallback((permissions: string[]): boolean => {
    if (state.isSuperAdmin) return true;
    return permissions.every(p => state.permissions.has(p));
  }, [state]);

  /**
   * Checks if user has any of the listed permissions (OR logic).
   */
  const canAny = useCallback((permissions: string[]): boolean => {
    if (state.isSuperAdmin) return true;
    return permissions.some(p => state.permissions.has(p));
  }, [state]);

  return {
    can,
    canAll,
    canAny,
    permissions: state.permissions,
    isLoaded: state.isLoaded,
    isSuperAdmin: state.isSuperAdmin,
  };
}

/**
 * Call this on logout to clear the permission cache.
 */
export function clearPermissionsCache() {
  permissionsCache.clear();
}
