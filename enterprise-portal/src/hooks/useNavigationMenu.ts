// @ts-nocheck
import { useState, useEffect, useCallback } from 'react';
import client from '../api/client';

export interface NavMenuItem {
  id: string;
  menuKey: string;
  portalTarget: string;
  displayLabel: string;
  iconKey: string;
  routePath: string;
  permissionKey: string;
  displayOrder: number;
  active: boolean;
  parentId: string | null;
  sectionLabel: string | null;
  children?: NavMenuItem[];
}

interface NavState {
  items: NavMenuItem[];
  isLoaded: boolean;
  error: string | null;
}

/**
 * useNavigationMenu — fetches portal navigation structure from the backend.
 *
 * Replaces the hardcoded SIDEBAR_ITEMS array in Layout.tsx.
 * The backend returns the authoritative navigation list from the database.
 * Admin can add/remove/reorder items without any code changes.
 *
 * API: GET /api/v1/config/navigation?portal=ENTERPRISE
 */

// Module-level cache — cleared on page refresh
let navCache: NavMenuItem[] | null = null;

export function useNavigationMenu(portal: string = 'ENTERPRISE') {
  const [state, setState] = useState<NavState>({
    items: navCache || [],
    isLoaded: navCache !== null,
    error: null,
  });

  const fetchNavigation = useCallback(async () => {
    if (navCache !== null) {
      setState({ items: navCache, isLoaded: true, error: null });
      return;
    }
    try {
      const res = await client.get('/api/v1/config/navigation', {
        params: { portal },
      });
      const rawItems: NavMenuItem[] = res.data?.data?.navigation || [];

      // Build hierarchy: separate top-level from children
      const itemMap = new Map<string, NavMenuItem>(rawItems.map(i => [i.id, { ...i, children: [] }]));
      const topLevel: NavMenuItem[] = [];

      rawItems.forEach(item => {
        const node = itemMap.get(item.id)!;
        if (item.parentId && itemMap.has(item.parentId)) {
          itemMap.get(item.parentId)!.children!.push(node);
        } else {
          topLevel.push(node);
        }
      });

      navCache = topLevel;
      setState({ items: topLevel, isLoaded: true, error: null });
    } catch (error) {
      console.error('[useNavigationMenu] Failed to load navigation:', error);
      // On error: return safe fallback minimal nav (dashboard only)
      const fallback: NavMenuItem[] = [
        {
          id: 'fallback-dashboard',
          menuKey: 'nav.dashboard',
          portalTarget: 'ENTERPRISE',
          displayLabel: 'Dashboard',
          iconKey: 'Dashboard',
          routePath: '/',
          permissionKey: 'dashboard:view',
          displayOrder: 1,
          active: true,
          parentId: null,
          sectionLabel: 'MAIN',
          children: [],
        }
      ];
      setState({ items: fallback, isLoaded: true, error: 'Navigation load failed' });
    }
  }, [portal]);

  useEffect(() => {
    fetchNavigation();
  }, [fetchNavigation]);

  return {
    navItems: state.items,
    isLoaded: state.isLoaded,
    error: state.error,
  };
}

/**
 * Clears the navigation cache (call on logout or after admin nav edits).
 */
export function clearNavCache() {
  navCache = null;
}
