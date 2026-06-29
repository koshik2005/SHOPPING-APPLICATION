import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Generic empty state widget with icon, title, subtitle, and optional CTA.
class _EmptyStateBase extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _EmptyStateBase({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: iconColor.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: iconColor),
            ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),
            const SizedBox(height: 20),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 100.ms),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 150.ms),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              FilledButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),
            ],
          ],
        ),
      ),
    );
  }
}

class EmptyOrdersState extends StatelessWidget {
  final VoidCallback? onShopNow;
  const EmptyOrdersState({super.key, this.onShopNow});
  @override
  Widget build(BuildContext context) {
    return _EmptyStateBase(
      icon: Icons.receipt_long_outlined,
      iconColor: const Color(0xFFFF6D00),
      title: 'No orders yet',
      subtitle: 'Your order history will appear here once you place your first order.',
      actionLabel: onShopNow != null ? 'Start Shopping' : null,
      onAction: onShopNow,
    );
  }
}

class EmptyCartState extends StatelessWidget {
  final VoidCallback? onBrowse;
  const EmptyCartState({super.key, this.onBrowse});
  @override
  Widget build(BuildContext context) {
    return _EmptyStateBase(
      icon: Icons.shopping_bag_outlined,
      iconColor: const Color(0xFF006D5B),
      title: 'Your cart is empty',
      subtitle: 'Add items from any shop or restaurant to get started.',
      actionLabel: onBrowse != null ? 'Browse Shops' : null,
      onAction: onBrowse,
    );
  }
}

class EmptySearchState extends StatelessWidget {
  final String? query;
  final VoidCallback? onClear;
  const EmptySearchState({super.key, this.query, this.onClear});
  @override
  Widget build(BuildContext context) {
    return _EmptyStateBase(
      icon: Icons.search_off,
      iconColor: const Color(0xFF85736B),
      title: query != null && query!.isNotEmpty ? 'No results for ""' : 'Search for anything',
      subtitle: 'Try different keywords or check your spelling.',
      actionLabel: (onClear != null && query != null && query!.isNotEmpty) ? 'Clear Search' : null,
      onAction: onClear,
    );
  }
}

class EmptySavedAddressesState extends StatelessWidget {
  final VoidCallback? onAddAddress;
  const EmptySavedAddressesState({super.key, this.onAddAddress});
  @override
  Widget build(BuildContext context) {
    return _EmptyStateBase(
      icon: Icons.location_on_outlined,
      iconColor: const Color(0xFFFF6D00),
      title: 'No saved addresses',
      subtitle: 'Save your home, office or favourite delivery locations for quick checkout.',
      actionLabel: onAddAddress != null ? 'Add Address' : null,
      onAction: onAddAddress,
    );
  }
}

class EmptyProductsState extends StatelessWidget {
  const EmptyProductsState({super.key});
  @override
  Widget build(BuildContext context) {
    return const _EmptyStateBase(
      icon: Icons.inventory_2_outlined,
      iconColor: Color(0xFF85736B),
      title: 'No products available',
      subtitle: 'This category has no products available at this branch right now. Please check back later.',
    );
  }
}

class EmptyNotificationsState extends StatelessWidget {
  const EmptyNotificationsState({super.key});
  @override
  Widget build(BuildContext context) {
    return const _EmptyStateBase(
      icon: Icons.notifications_none,
      iconColor: Color(0xFF006D5B),
      title: 'All caught up!',
      subtitle: 'You have no new notifications. We will alert you about orders, offers and updates.',
    );
  }
}

class NoBranchState extends StatelessWidget {
  final VoidCallback? onRetry;
  const NoBranchState({super.key, this.onRetry});
  @override
  Widget build(BuildContext context) {
    return _EmptyStateBase(
      icon: Icons.store_mall_directory_outlined,
      iconColor: const Color(0xFFBA1A1A),
      title: 'No branch available',
      subtitle: 'There are no active branches serving your area right now.',
      actionLabel: onRetry != null ? 'Retry' : null,
      onAction: onRetry,
    );
  }
}
