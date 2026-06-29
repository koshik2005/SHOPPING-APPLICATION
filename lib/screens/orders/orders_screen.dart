import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/state.dart';
import '../../widgets/card.dart';
import '../../widgets/button.dart';
import '../../widgets/badge.dart';
import '../../widgets/feedback.dart';
import '../../widgets/skeletons.dart';
import '../../widgets/empty_states.dart';
import '../../lip/lip_di.dart';
import '../../lip/domain/map_provider.dart' as lip;
import 'package:latlong2/latlong.dart';

// --------------------------------------------------------------------------
// 1. Checkout Overview Screen
// --------------------------------------------------------------------------
class CheckoutScreen extends ConsumerWidget {
  const CheckoutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    
    // Read dynamic states
    final cart = ref.watch(dynamicCartProvider);
    final walletBal = ref.watch(walletProvider);
    final user = ref.watch(userProfileProvider);
    final config = ref.watch(appConfigProvider);

    double subtotal = cart.fold<double>(0.0, (sum, item) => sum + (item.product.price * item.quantity));
    final grandTotal = subtotal + config.baseDeliveryFee + config.platformFee + (subtotal * config.taxRate);

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    HyperLocalCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.local_shipping, color: theme.colorScheme.primary),
                              const SizedBox(width: 8),
                              Text('Delivery Address', style: theme.textTheme.titleMedium),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text('${user.name} • ${user.mobileNumber}', style: const TextStyle(fontWeight: FontWeight.w500)),
                          Text(
                            user.addresses.isNotEmpty ? user.addresses.first : 'No address set',
                            style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    HyperLocalCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.credit_card, color: theme.colorScheme.primary),
                              const SizedBox(width: 8),
                              Text('Payment Summary', style: theme.textTheme.titleMedium),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('HyperWallet'),
                              Text('\$${walletBal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    HyperLocalCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.confirmation_number_outlined, color: theme.colorScheme.primary),
                              const SizedBox(width: 8),
                              Text('Promo Voucher', style: theme.textTheme.titleMedium),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Expanded(
                                child: SizedBox(
                                  height: 40,
                                  child: TextField(
                                    decoration: InputDecoration(
                                      hintText: 'Enter Voucher Code',
                                      contentPadding: EdgeInsets.symmetric(horizontal: 12),
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 80,
                                height: 40,
                                child: ElevatedButton(
                                  onPressed: () {},
                                  child: const Text('Apply'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            HyperLocalButton(
              label: 'Pay \$${grandTotal.toStringAsFixed(2)}',
              variant: ButtonVariant.secondary,
              onPressed: () => context.push('/processing'),
            ),
          ],
        ),
      ),
    );
  }
}

// --------------------------------------------------------------------------
// 2. Processing Screen
// --------------------------------------------------------------------------
class ProcessingScreen extends ConsumerStatefulWidget {
  const ProcessingScreen({super.key});

  @override
  ConsumerState<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends ConsumerState<ProcessingScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) {
        final cart = ref.read(dynamicCartProvider);
        final user = ref.read(userProfileProvider);
        final config = ref.read(appConfigProvider);
        
        double subtotal = cart.fold<double>(0.0, (sum, item) => sum + (item.product.price * item.quantity));
        final grandTotal = subtotal + config.baseDeliveryFee + config.platformFee + (subtotal * config.taxRate);

        try {
          ref.read(walletRepositoryProvider).debit(
            '87ef769c-d021-4f11-ba32-aafe812bb31c',
            grandTotal,
          ).then((_) {
            ref.read(orderRepositoryProvider).createOrder(
              '87ef769c-d021-4f11-ba32-aafe812bb31c',
              {
                'branchId': '87ef769c-d021-4f11-ba32-aafe812bb31c',
                'items': cart.map((i) => {
                  'productVariantId': '39cd7810-ff99-4c12-ab88-ffeeddaa2211',
                  'quantity': i.quantity,
                  'price': i.product.price,
                }).toList(),
              },
            );
          });
        } catch (e) {
          debugPrint('Transaction failed: $e');
        }

        ref.read(dynamicCartProvider.notifier).clear();
        context.go('/orders');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const ShimmerLoader(width: 80, height: 80, borderRadius: 40),
              const SizedBox(height: 24),
              Text(
                'Securing Payment',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.secondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Connecting with secure payment systems. Please do not close application.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.security, size: 16, color: theme.colorScheme.outline),
                  const SizedBox(width: 4),
                  Text('PCI-DSS Compliant', style: TextStyle(color: theme.colorScheme.outline, fontSize: 12)),
                  const SizedBox(width: 24),
                  Icon(Icons.verified_user, size: 16, color: theme.colorScheme.outline),
                  const SizedBox(width: 4),
                  Text('256-Bit SSL', style: TextStyle(color: theme.colorScheme.outline, fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --------------------------------------------------------------------------
// 3. Orders List Screen
// --------------------------------------------------------------------------
class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ordersAsync = ref.watch(userOrdersProvider);
    
    return Scaffold(
      appBar: AppBar(title: const Text('My Orders')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(elevation: 0),
                    child: const Text('Active'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(onPressed: () {}, child: const Text('Scheduled')),
                  const SizedBox(width: 8),
                  OutlinedButton(onPressed: () {}, child: const Text('Completed')),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ordersAsync.when(
                loading: () => const OrdersScreenSkeleton(),
                error: (err, stack) => Center(child: Text('Failed to load orders: $err')),
                data: (orders) {
                  if (orders.isEmpty) {
                    return EmptyOrdersState(onShopNow: () => context.go('/home'));
                  }
                  return ListView.builder(
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      final order = orders[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: HyperLocalCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(order['storeName'] ?? 'Local Merchant Hub', style: theme.textTheme.titleMedium),
                                      Text(
                                        '${order['timestamp'] ?? 'Today'} • Order #${order['id'] ?? 'HL-9824'}',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: theme.colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                  HyperLocalBadge(label: order['status'] ?? 'Preparing', category: BadgeType.status),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                order['itemsText'] ?? '',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '\$${(order['price'] as num?)?.toStringAsFixed(2) ?? '0.00'}',
                                    style: theme.textTheme.titleMedium,
                                  ),
                                  SizedBox(
                                    width: 100,
                                    height: 36,
                                    child: HyperLocalButton(
                                      label: 'Track Live',
                                      onPressed: () => context.push('/tracking'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}

// --------------------------------------------------------------------------
// 4. Live Tracking & Timeline Screen
// --------------------------------------------------------------------------
class TrackingScreen extends ConsumerStatefulWidget {
  const TrackingScreen({super.key});

  @override
  ConsumerState<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends ConsumerState<TrackingScreen> {
  List<LatLng> _polyline = [];
  bool _calculating = false;
  LatLng? _lastRiderPos;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final track = ref.watch(trackingProvider);
    
    final customerLoc = const LatLng(37.7749, -122.4194);
    final riderLoc = LatLng(track.riderLat, track.riderLng);

    if (_lastRiderPos != riderLoc && !_calculating) {
      _lastRiderPos = riderLoc;
      _calculating = true;
      ref.read(routeProvider).calculateRoute(riderLoc, customerLoc).then((route) {
        if (mounted) {
          setState(() {
            _polyline = route.polyline;
            _calculating = false;
          });
        }
      }).catchError((_) {
        if (mounted) {
          setState(() => _calculating = false);
        }
      });
    }

    final mProvider = ref.watch(mapProvider);
    
    final markers = [
      lip.MapMarker(
        id: 'rider',
        position: riderLoc,
        type: lip.MarkerType.deliveryPartner,
        title: track.driverName,
      ),
      lip.MapMarker(
        id: 'customer',
        position: customerLoc,
        type: lip.MarkerType.customer,
        title: 'Your Home',
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Live Tracking')),
      body: Column(
        children: [
          Expanded(
            child: mProvider.buildMapWidget(
              initialCenter: riderLoc,
              initialZoom: 14.5,
              routePolyline: _polyline,
              markers: markers,
              onCameraMove: (_) {},
            ),
          ),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(28),
                topRight: Radius.circular(28),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Arriving in ${track.etaMinutes}', style: theme.textTheme.titleLarge),
                          Text(
                            '${track.driverName} is moving at ${track.currentSpeedMph.toStringAsFixed(1)} mph • ${track.remainingDistanceMiles.toStringAsFixed(1)} mi left',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SuccessConcentricCheck(icon: Icons.motorcycle),
                  ],
                ),
                const SizedBox(height: 24),
                
                Row(
                  children: [
                    Icon(Icons.check_circle, size: 16, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text('Order Picked Up', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.radio_button_unchecked, size: 16, color: theme.colorScheme.outline),
                    const SizedBox(width: 8),
                    Text('Rider Near Your Home', style: TextStyle(color: theme.colorScheme.outline)),
                  ],
                ),
                const SizedBox(height: 24),
                
                Row(
                  children: [
                    Expanded(
                      child: HyperLocalButton(
                        label: 'Chat support',
                        variant: ButtonVariant.outlined,
                        onPressed: () => context.push('/chat'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: HyperLocalButton(
                        label: 'Go to Home',
                        onPressed: () => context.go('/home'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
