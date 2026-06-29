import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';

class AppShell extends StatelessWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  int _getSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/search')) return 1;
    if (location.startsWith('/orders')) return 2;
    if (location.startsWith('/wallet')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    HapticFeedback.selectionClick();
    switch (index) {
      case 0: GoRouter.of(context).go('/home'); break;
      case 1: GoRouter.of(context).go('/search'); break;
      case 2: GoRouter.of(context).go('/orders'); break;
      case 3: GoRouter.of(context).go('/wallet'); break;
      case 4: GoRouter.of(context).go('/profile'); break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.of(context).size.width;
    final isLargeScreen = width >= 600; // MD3 Tablet Breakpoint
    
    final selectedIndex = _getSelectedIndex(context);

    if (isLargeScreen) {
      // 1. Navigation Rail for Tablet / Landscape / Foldable viewport orientations
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: selectedIndex,
              onDestinationSelected: (index) => _onItemTapped(index, context),
              backgroundColor: theme.colorScheme.surfaceContainer,
              indicatorColor: theme.colorScheme.primaryContainer,
              labelType: NavigationRailLabelType.all,
              selectedLabelTextStyle: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w600, fontSize: 12),
              unselectedLabelTextStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12),
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home, color: AppColorPlaceholder.primary),
                  label: Text('Home'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.search_outlined),
                  selectedIcon: Icon(Icons.search),
                  label: Text('Search'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.receipt_long_outlined),
                  selectedIcon: Icon(Icons.receipt_long),
                  label: Text('Orders'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.account_balance_wallet_outlined),
                  selectedIcon: Icon(Icons.account_balance_wallet),
                  label: Text('Wallet'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person),
                  label: Text('Profile'),
                ),
              ],
            ),
            const VerticalDivider(width: 1, thickness: 1),
            Expanded(child: child),
          ],
        ),
      );
    }

    // 2. Navigation Bar for compact Phone viewport sizes
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) => _onItemTapped(index, context),
        backgroundColor: theme.colorScheme.surfaceContainer,
        indicatorColor: theme.colorScheme.primaryContainer,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search),
            label: 'Search',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Orders',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'Wallet',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// Temporary placeholder class to avoid compiler errors during build stages
class AppColorPlaceholder {
  static const Color primary = Color(0xFFFF6D00);
}
