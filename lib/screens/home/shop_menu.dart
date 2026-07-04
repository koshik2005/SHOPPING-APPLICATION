import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/state.dart';
import '../../widgets/card.dart';
import '../../widgets/button.dart';
import '../../widgets/feedback.dart';
import '../../widgets/badge.dart';
import '../../widgets/empty_states.dart';

class ShopScreen extends ConsumerWidget {
  final String categoryId;
  const ShopScreen({super.key, required this.categoryId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    
    final currentBranchKey = ref.watch(selectedBranchProvider);
    final rawCatalog = ref.watch(catalogProvider(currentBranchKey));
    // Filter catalog items to only show products matching the selected category ID
    final catalog = rawCatalog.where((p) => p.categoryId == categoryId).toList();
    
    final cart = ref.watch(dynamicCartProvider);
    final merchants = ref.watch(merchantListProvider);
    
    final merchant = merchants.isNotEmpty 
        ? (merchants.any((m) => m.id == 'm1') ? merchants.firstWhere((m) => m.id == 'm1') : merchants.first)
        : MerchantInfo(
            id: 'default',
            name: 'Local Merchant',
            logoUrl: '',
            bannerUrl: '',
            rating: 4.8,
            openingTime: '08:00 AM',
            closingTime: '09:00 PM',
            deliveryFee: 1.99,
            minOrderValue: 10.0,
            averagePrepTimeMinutes: 15,
          );
    final totalItems = cart.fold<int>(0, (sum, item) => sum + item.quantity);

    return Scaffold(
      appBar: AppBar(
        title: Text(merchant.name),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: theme.colorScheme.secondaryContainer,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              children: [
                Text(
                  merchant.name,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Fresh local items loaded directly from merchant catalogs.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const HyperLocalBadge(label: 'Free Delivery', category: BadgeType.delivery),
                    const SizedBox(width: 8),
                    HyperLocalBadge(label: '${merchant.rating} ★', category: BadgeType.feature),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: catalog.isEmpty
                ? const EmptyProductsState()
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: catalog.length,
              itemBuilder: (context, index) {
                final item = catalog[index];
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: HyperLocalCard(
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFDBC8),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(item.imageUrl.contains('avocado') ? '🥑' : '🍞', style: const TextStyle(fontSize: 24)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.name, style: theme.textTheme.titleSmall),
                              const SizedBox(height: 2),
                              Text('\$${item.price.toStringAsFixed(2)}', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 72,
                          height: 36,
                          child: ElevatedButton(
                            onPressed: () {
                              ref.read(dynamicCartProvider.notifier).addItem(item, 'Standard');
                              showCustomToast(context, '${item.name} added!');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: theme.colorScheme.onPrimary,
                              elevation: 0,
                              padding: EdgeInsets.zero,
                            ),
                            child: const Text('Add', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Cart Preview Strip
          Container(
            padding: const EdgeInsets.all(16),
            color: theme.colorScheme.surfaceContainerHigh,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$totalItems Item${totalItems == 1 ? "" : "s"} in Cart',
                      style: theme.textTheme.titleSmall,
                    ),
                    const Text(
                      'Delivery fees calculated dynamically',
                      style: TextStyle(fontSize: 11),
                    ),
                  ],
                ),
                SizedBox(
                  width: 120,
                  child: HyperLocalButton(
                    label: 'View Cart',
                    onPressed: () => context.push('/cart'),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cart = ref.watch(dynamicCartProvider);
    final isOnline = ref.watch(connectivityStateProvider);
    final config = ref.watch(appConfigProvider);

    if (cart.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Cart')),
        body: EmptyCartState(
          onBrowse: () => context.go('/home'),
        ),
      );
    }

    double subtotal = cart.fold<double>(0.0, (sum, item) => sum + (item.product.price * item.quantity));
    
    // Dynamic fee calculations based on backend config rules
    double calculatedDeliveryFee = config.baseDeliveryFee;
    double platformFee = config.platformFee;
    double tax = subtotal * config.taxRate;
    double grandTotal = subtotal + calculatedDeliveryFee + platformFee + tax;

    return Scaffold(
      appBar: AppBar(title: const Text('My Cart')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: cart.length,
                itemBuilder: (context, index) {
                  final item = cart[index];
                  final itemTotal = item.product.price * item.quantity;
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: HyperLocalCard(
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFDBC8),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(item.product.imageUrl.contains('avocado') ? '🥑' : '🍞', style: const TextStyle(fontSize: 24)),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.product.name, style: theme.textTheme.titleSmall),
                                const SizedBox(height: 4),
                                Text(
                                  '\$${itemTotal.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: theme.colorScheme.outline),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove, size: 16),
                                  onPressed: () {
                                    ref.read(dynamicCartProvider.notifier).updateQuantity(item.product.id, item.product.categoryId, item.selectedVariant, -1);
                                  },
                                ),
                                Text('${item.quantity}', style: theme.textTheme.titleSmall),
                                IconButton(
                                  icon: const Icon(Icons.add, size: 16),
                                  onPressed: () {
                                    ref.read(dynamicCartProvider.notifier).updateQuantity(item.product.id, item.product.categoryId, item.selectedVariant, 1);
                                  },
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Subtotal'),
                      Text('\$${subtotal.toStringAsFixed(2)}', style: theme.textTheme.titleSmall),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Delivery Fee (Dynamic)'),
                      Text('\$${calculatedDeliveryFee.toStringAsFixed(2)}', style: theme.textTheme.titleSmall),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Platform Fee'),
                      Text('\$${platformFee.toStringAsFixed(2)}', style: theme.textTheme.titleSmall),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Estimated Total', style: theme.textTheme.titleMedium),
                      Text(
                        '\$${grandTotal.toStringAsFixed(2)}',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            HyperLocalButton(
              label: 'Proceed to Checkout',
              onPressed: () {
                if (!isOnline) {
                  context.push('/system-state', extra: {'status': 'no-internet'});
                } else {
                  context.push('/checkout');
                }
              },
            )
          ],
        ),
      ),
    );
  }
}
